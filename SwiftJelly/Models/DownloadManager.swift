//
//  DownloadManager.swift
//  SwiftJelly
//

import Foundation
import JellyfinAPI
import SwiftUI

enum DownloadStatus: String, Codable {
    case downloading
    case completed
    case failed
}

struct DownloadRecord: Codable, Identifiable {
    let id: String
    let item: BaseItemDto
    let fileName: String
    var status: DownloadStatus
    var bytesWritten: Int64
    var totalBytes: Int64
    var dateAdded: Date
    var serverID: String?
}

@MainActor
@Observable
final class DownloadManager: NSObject {
    static let shared = DownloadManager()

    private(set) var downloads: [String: DownloadRecord] = [:]

    @ObservationIgnored private var tasks: [String: URLSessionDownloadTask] = [:]

    /// System-invoked completion handler set by `application(_:handleEventsForBackgroundURLSession:completionHandler:)`.
    var backgroundCompletionHandler: (() -> Void)?

    @ObservationIgnored private static let backgroundSessionIdentifier = "com.swiftjelly.downloads"

    @ObservationIgnored private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: Self.backgroundSessionIdentifier)
        config.allowsCellularAccess = true
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }()

    @ObservationIgnored private let metadataURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Downloads", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("downloads.json")
    }()

    @ObservationIgnored private let downloadsDirectory: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Downloads", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    override private init() {
        super.init()
        loadMetadata()
        // Touch session to reattach to any pending background tasks left over from
        // a previous launch and reconcile our metadata against in-flight tasks.
        reconcileWithRunningTasks()
    }

    private func reconcileWithRunningTasks() {
        session.getAllTasks { [weak self] runningTasks in
            Task { @MainActor [weak self] in
                guard let self else { return }
                var liveIDs = Set<String>()
                for task in runningTasks {
                    if let id = task.taskDescription, !id.isEmpty {
                        liveIDs.insert(id)
                        if let download = task as? URLSessionDownloadTask {
                            self.tasks[id] = download
                        }
                    }
                }
                // Mark records that claim to be downloading but have no live task as failed.
                for (id, var record) in self.downloads where record.status == .downloading && !liveIDs.contains(id) {
                    record.status = .failed
                    self.downloads[id] = record
                }
                self.saveMetadata()
            }
        }
    }

    // MARK: - Public queries

    func record(for itemID: String?) -> DownloadRecord? {
        guard let itemID else { return nil }
        return downloads[itemID]
    }

    func localFileURL(for itemID: String) -> URL? {
        guard let record = downloads[itemID], record.status == .completed else { return nil }
        let url = downloadsDirectory.appendingPathComponent(record.fileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func progress(for itemID: String) -> Double {
        guard let r = downloads[itemID], r.totalBytes > 0 else { return 0 }
        return min(1.0, Double(r.bytesWritten) / Double(r.totalBytes))
    }

    func sortedRecords() -> [DownloadRecord] {
        downloads.values.sorted { $0.dateAdded > $1.dateAdded }
    }

    // MARK: - Mutations

    func startDownload(for item: BaseItemDto) {
        guard let itemID = item.id else { return }
        if let existing = downloads[itemID],
           existing.status == .completed || existing.status == .downloading {
            return
        }

        do {
            let url = try JFAPI.downloadURL(for: item)
            // We always request the server to deliver an MP4 (remuxed when
            // possible), so the on-disk file is always .mp4 regardless of
            // the source container.
            let fileName = "\(itemID).mp4"

            let record = DownloadRecord(
                id: itemID,
                item: item,
                fileName: fileName,
                status: .downloading,
                bytesWritten: 0,
                totalBytes: 0,
                dateAdded: Date(),
                serverID: DataManager.shared.activeServerID
            )
            downloads[itemID] = record
            saveMetadata()

            let task = session.downloadTask(with: url)
            task.taskDescription = itemID
            tasks[itemID] = task
            task.resume()
        } catch {
            print("Download start failed: \(error)")
        }
    }

    func cancelDownload(for itemID: String) {
        tasks[itemID]?.cancel()
        tasks[itemID] = nil
        downloads[itemID] = nil
        let url = downloadsDirectory
        try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix(itemID + ".") }
            .forEach { try? FileManager.default.removeItem(at: $0) }
        saveMetadata()
    }

    func deleteDownload(for itemID: String) {
        if let record = downloads[itemID] {
            let fileURL = downloadsDirectory.appendingPathComponent(record.fileName)
            try? FileManager.default.removeItem(at: fileURL)
        }
        tasks[itemID]?.cancel()
        tasks[itemID] = nil
        downloads[itemID] = nil
        saveMetadata()
    }

    // MARK: - Persistence

    private func loadMetadata() {
        guard let data = try? Data(contentsOf: metadataURL),
              let decoded = try? JSONDecoder().decode([String: DownloadRecord].self, from: data) else {
            return
        }
        // Keep "downloading" records as-is — `reconcileWithRunningTasks` will downgrade
        // any that no longer have a live URLSession task.
        downloads = decoded
    }

    private func saveMetadata() {
        if let data = try? JSONEncoder().encode(downloads) {
            try? data.write(to: metadataURL, options: .atomic)
        }
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        // delegateQueue is .main, so we are on the main thread here.
        MainActor.assumeIsolated {
            let itemID = downloadTask.taskDescription ?? ""
            guard var record = downloads[itemID] else { return }

            // Treat non-2xx responses as failure — Jellyfin returns plain-text
            // error bodies which would otherwise be saved with an .mp4
            // extension and look "downloaded" to the UI.
            if let http = downloadTask.response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                record.status = .failed
                downloads[itemID] = record
                tasks[itemID] = nil
                saveMetadata()
                return
            }

            let dest = downloadsDirectory.appendingPathComponent(record.fileName)
            try? FileManager.default.removeItem(at: dest)
            do {
                try FileManager.default.moveItem(at: location, to: dest)
                record.status = .completed
                if record.totalBytes <= 0 {
                    record.totalBytes = (try? FileManager.default.attributesOfItem(atPath: dest.path)[.size] as? Int64) ?? 0
                }
                record.bytesWritten = record.totalBytes
            } catch {
                record.status = .failed
            }
            downloads[itemID] = record
            tasks[itemID] = nil
            saveMetadata()
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        MainActor.assumeIsolated {
            let itemID = downloadTask.taskDescription ?? ""
            guard var record = downloads[itemID] else { return }
            record.bytesWritten = totalBytesWritten
            record.totalBytes = max(record.totalBytes, totalBytesExpectedToWrite)
            downloads[itemID] = record
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error else { return }
        if (error as NSError).code == NSURLErrorCancelled { return }
        MainActor.assumeIsolated {
            let itemID = task.taskDescription ?? ""
            guard var record = downloads[itemID] else { return }
            record.status = .failed
            downloads[itemID] = record
            tasks[itemID] = nil
            saveMetadata()
        }
    }

    nonisolated func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        MainActor.assumeIsolated {
            let handler = backgroundCompletionHandler
            backgroundCompletionHandler = nil
            handler?()
        }
    }
}
