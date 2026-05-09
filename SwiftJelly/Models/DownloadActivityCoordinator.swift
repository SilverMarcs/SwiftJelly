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
    }

    /// Total units of the fake-progress bar. Generous so the bar advances
    /// visibly without ever reaching the cap during a typical download.
    private static let fakeProgressTotal: Int64 = 1000
    /// Minimum spacing between fake-progress ticks so a high-rate URLSession
    /// callback stream doesn't race the bar to the cap in seconds.
    private static let progressTickInterval: TimeInterval = 0.5

    private var activeTask: BGContinuedProcessingTask?
    private var tracked: [String: Tracked] = [:]
    private var lastTickAt: TimeInterval = 0

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

    func startTracking(itemID: String, name: String) {
        if tracked[itemID] == nil {
            tracked[itemID] = Tracked(name: name)
        }
        ensureTaskRunning()
        refreshActivity(tickProgress: false)
    }

    func updateProgress(itemID: String, bytesWritten: Int64, totalBytes: Int64) {
        // Real bytes are ignored for the bar — Jellyfin's `/Items/{id}/Download`
        // often replies without a `Content-Length` header, so a real-progress
        // bar either pegs at 100% immediately or jitters wildly. A creeping
        // fake bar that never reaches the cap until completion looks honest.
        guard tracked[itemID] != nil else { return }
        refreshActivity(tickProgress: true)
    }

    func stopTracking(itemID: String, success: Bool = true) {
        guard tracked.removeValue(forKey: itemID) != nil else { return }
        if tracked.isEmpty {
            if success {
                // Snap the bar to full just before teardown so the user sees a
                // definite "done" frame on the Live Activity.
                activeTask?.progress.completedUnitCount = Self.fakeProgressTotal
            }
            activeTask?.setTaskCompleted(success: success)
            activeTask = nil
        } else {
            refreshActivity(tickProgress: false)
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
        // refuse to launch the task at all. Mirrors the LynkChat pattern.
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
        task.progress.totalUnitCount = Self.fakeProgressTotal
        task.progress.completedUnitCount = 0
        lastTickAt = 0
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
        refreshActivity(tickProgress: false)
    }

    private func refreshActivity(tickProgress: Bool) {
        guard let task = activeTask else { return }

        if tickProgress {
            let now = ProcessInfo.processInfo.systemUptime
            if now - lastTickAt >= Self.progressTickInterval {
                lastTickAt = now
                let cap = Self.fakeProgressTotal - 1
                if task.progress.completedUnitCount < cap {
                    task.progress.completedUnitCount += 1
                }
            }
        }

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
