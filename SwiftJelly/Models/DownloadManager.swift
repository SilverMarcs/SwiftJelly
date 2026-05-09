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

    /// Foreground-only session. Tasks die when the app is suspended; the user
    /// can retry from the UI on a failed record.
    @ObservationIgnored private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.waitsForConnectivity = true
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
        // No tasks survive process death — anything that says "downloading"
        // from a previous launch is stale, mark it failed so the user can retry.
        markStaleDownloadsAsFailed()
    }

    private func markStaleDownloadsAsFailed() {
        var changed = false
        for (id, var record) in downloads where record.status == .downloading {
            record.status = .failed
            downloads[id] = record
            changed = true
        }
        if changed { saveMetadata() }
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
        if let existing = downloads[itemID] {
            if existing.status == .completed { return }
            if tasks[itemID] != nil { return }
            // Otherwise it's a failed record the user is retrying.
        }

        do {
            let url = try JFAPI.downloadURL(for: item)
            let record = DownloadRecord(
                id: itemID,
                item: item,
                fileName: "\(itemID).mp4",
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
            #if os(iOS)
            DownloadActivityCoordinator.shared.startTracking(
                itemID: itemID,
                name: item.name ?? "Item"
            )
            #endif
        } catch {
            print("Download start failed: \(error)")
        }
    }

    func cancelDownload(for itemID: String) {
        tasks[itemID]?.cancel()
        tasks[itemID] = nil
        downloads[itemID] = nil
        try? FileManager.default
            .contentsOfDirectory(at: downloadsDirectory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix(itemID + ".") }
            .forEach { try? FileManager.default.removeItem(at: $0) }
        saveMetadata()
        #if os(iOS)
        DownloadActivityCoordinator.shared.stopTracking(itemID: itemID, success: false)
        #endif
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
        #if os(iOS)
        DownloadActivityCoordinator.shared.stopTracking(itemID: itemID)
        #endif
    }

    // MARK: - Persistence

    private func loadMetadata() {
        guard let data = try? Data(contentsOf: metadataURL),
              let decoded = try? JSONDecoder().decode([String: DownloadRecord].self, from: data) else {
            return
        }
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
                #if os(iOS)
                DownloadActivityCoordinator.shared.stopTracking(itemID: itemID, success: false)
                #endif
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
            #if os(iOS)
            DownloadActivityCoordinator.shared.stopTracking(itemID: itemID)
            #endif
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
            #if os(iOS)
            DownloadActivityCoordinator.shared.updateProgress(
                itemID: itemID,
                bytesWritten: record.bytesWritten,
                totalBytes: record.totalBytes
            )
            #endif
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error else { return }
        MainActor.assumeIsolated {
            let itemID = task.taskDescription ?? ""
            // User-initiated cancel removes the record before this fires;
            // missing record == nothing to do.
            guard var record = downloads[itemID] else { return }
            // Anything else (network drop, suspension, server error) is a failure.
            // The user can retry from the UI.
            _ = error
            record.status = .failed
            downloads[itemID] = record
            tasks[itemID] = nil
            saveMetadata()
            #if os(iOS)
            DownloadActivityCoordinator.shared.stopTracking(itemID: itemID, success: false)
            #endif
        }
    }
}
