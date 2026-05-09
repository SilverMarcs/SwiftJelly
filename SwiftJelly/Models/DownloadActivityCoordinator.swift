//
//  DownloadActivityCoordinator.swift
//  SwiftJelly
//

#if os(iOS)
import Foundation
import BackgroundTasks

/// Wraps a single `BGContinuedProcessingTask` that umbrella-tracks every
/// in-flight download. While this task is alive the system keeps the app
/// running past suspension, which means our regular foreground `URLSession`
/// downloads keep going at full speed. Progress is surfaced to the user as a
/// system-provided Live Activity (title / subtitle / progress bar) which they
/// can also use to cancel.
@MainActor
final class DownloadActivityCoordinator {
    static let shared = DownloadActivityCoordinator()

    static let taskIdentifier = "com.SilverMarcs.SwiftJelly.downloads"

    private struct Tracked {
        var name: String
        /// Source file size from Jellyfin (`MediaSourceInfo.size`). May be 0
        /// if the server didn't report one — we substitute a placeholder so
        /// the bar still makes visible progress.
        var sourceFileSize: Int64
        var bytesWritten: Int64
    }

    /// Used when Jellyfin doesn't expose a source file size — gives the bar
    /// something large enough to crawl across without falsely hitting 100%
    /// for any realistic download.
    private static let unknownSizeFallback: Int64 = 1_000_000_000  // 1 GB
    /// Multiplier on source size: the actual download may exceed the source
    /// file size if Jellyfin transcodes (different container/codec/bitrate).
    /// Doubling gives plenty of room without the bar saturating early.
    private static let sizeMultiplier: Int64 = 2

    private var activeTask: BGContinuedProcessingTask?
    private var tracked: [String: Tracked] = [:]

    private init() {}

    /// Call once at app launch (before any task is submitted).
    static func register() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: .main
        ) { task in
            guard let continued = task as? BGContinuedProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            MainActor.assumeIsolated {
                shared.adopt(task: continued)
            }
        }
    }

    // MARK: - Lifecycle hooks called from DownloadManager

    func startTracking(itemID: String, name: String, sourceFileSize: Int64) {
        if tracked[itemID] == nil {
            let effectiveSize = sourceFileSize > 0 ? sourceFileSize : Self.unknownSizeFallback
            tracked[itemID] = Tracked(
                name: name,
                sourceFileSize: effectiveSize,
                bytesWritten: 0
            )
        }
        ensureTaskRunning()
        refreshActivity()
    }

    func updateProgress(itemID: String, bytesWritten: Int64) {
        guard var t = tracked[itemID] else { return }
        t.bytesWritten = bytesWritten
        tracked[itemID] = t
        refreshActivity()
    }

    func stopTracking(itemID: String, success: Bool = true) {
        guard tracked.removeValue(forKey: itemID) != nil else { return }
        if tracked.isEmpty {
            if success, let task = activeTask {
                // Snap the bar to full just before teardown so the user sees a
                // definite "done" frame on the Live Activity.
                task.progress.completedUnitCount = task.progress.totalUnitCount
            }
            activeTask?.setTaskCompleted(success: success)
            activeTask = nil
        } else {
            refreshActivity()
        }
    }

    // MARK: - Internal

    private func ensureTaskRunning() {
        guard activeTask == nil else { return }
        let request = BGContinuedProcessingTaskRequest(
            identifier: Self.taskIdentifier,
            title: title,
            subtitle: subtitle
        )
        // `.queue` lets iOS queue the request rather than reject it under
        // resource pressure — without an explicit strategy the system can
        // refuse to launch the task at all.
        request.strategy = .queue
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // The download itself still proceeds; we just lose the
            // background-life-extension benefit. Most common failure: the
            // identifier isn't in BGTaskSchedulerPermittedIdentifiers.
            print("BGContinuedProcessingTask submit failed: \(error)")
        }
    }

    private func adopt(task: BGContinuedProcessingTask) {
        activeTask = task
        task.expirationHandler = { [weak self] in
            // System (or user via Live Activity) is asking us to stop. Cancel
            // every in-flight download; the manager will tear down each
            // URLSessionDownloadTask and flip records to .failed so the user
            // can retry from the UI.
            Task { @MainActor in
                guard let self else { return }
                let ids = Array(self.tracked.keys)
                for id in ids {
                    DownloadManager.shared.cancelDownload(for: id)
                }
                self.tracked.removeAll()
                self.activeTask = nil
            }
        }
        refreshActivity()
    }

    private func refreshActivity() {
        guard let task = activeTask else { return }

        // Total = 2× the sum of known source sizes. Doubling means even a
        // download that grows above the source size during transcoding never
        // reads "complete" before we explicitly snap it on stopTracking.
        let totalUnits = tracked.values.reduce(Int64(0)) {
            $0 + $1.sourceFileSize * Self.sizeMultiplier
        }
        let writtenUnits = tracked.values.reduce(Int64(0)) { $0 + $1.bytesWritten }
        let safeTotal = max(totalUnits, 1)
        let cap = max(safeTotal - 1, 1)

        task.progress.totalUnitCount = safeTotal
        task.progress.completedUnitCount = min(writtenUnits, cap)

        task.updateTitle(title, subtitle: subtitle)
    }

    private var title: String {
        let count = tracked.count
        if count == 0 { return "Downloads" }
        if count == 1 { return "Downloading" }
        return "Downloading \(count) items"
    }

    private var subtitle: String {
        if tracked.isEmpty { return "" }
        if tracked.count == 1, let only = tracked.values.first {
            return only.name
        }
        let names = tracked.values.map(\.name).sorted()
        guard let first = names.first else { return "" }
        return "\(first) and \(names.count - 1) more"
    }
}
#endif
