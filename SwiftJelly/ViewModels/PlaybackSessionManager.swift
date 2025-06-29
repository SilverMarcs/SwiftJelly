//
//  PlaybackSessionManager.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 29/06/2025.
//

import Foundation
import JellyfinAPI
import Combine

/// Manages playback session reporting to Jellyfin server
class PlaybackSessionManager: ObservableObject {
    @Published private(set) var playSessionID: String = ""
    @Published private(set) var hasSentStart: Bool = false
    
    private var progressReportTask: Task<Void, Never>?
    private let item: BaseItemDto
    
    init(item: BaseItemDto) {
        self.item = item
        self.playSessionID = JFAPI.shared.generatePlaySessionID()
    }
    
    deinit {
        progressReportTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Starts the playback session and begins progress reporting
    func startPlayback(at positionSeconds: Int) {
        guard !hasSentStart else { return }
        
        hasSentStart = true
        sendStartReport(positionSeconds: positionSeconds)
    }
    
    /// Reports playback pause
    func pausePlayback(at positionSeconds: Int) {
        stopProgressReporting()
        sendPauseReport(positionSeconds: positionSeconds)
    }
    
    /// Reports playback resume and restarts progress reporting
    func resumePlayback(at positionSeconds: Int) {
        sendResumeReport(positionSeconds: positionSeconds)
        startProgressReporting(currentSeconds: positionSeconds)
    }
    
    /// Reports playback stop and cleans up session
    func stopPlayback(at positionSeconds: Int) {
        stopProgressReporting()
        
        if hasSentStart {
            sendStopReport(positionSeconds: positionSeconds)
        }
    }
    
    /// Updates progress reporting with current position (called periodically during playback)
    func updateProgress(currentSeconds: Int, isPlaying: Bool) {
        if isPlaying && hasSentStart {
            // Progress reporting is handled by the periodic task
            // This method can be used for any additional logic if needed
        }
    }
    
    // MARK: - Private Methods
    
    private func sendStartReport(positionSeconds: Int) {
        Task {
            do {
                try await JFAPI.shared.reportPlaybackStart(
                    for: item,
                    positionTicks: positionSeconds.toPositionTicks,
                    playSessionID: playSessionID
                )
                startProgressReporting(currentSeconds: positionSeconds)
            } catch {
                print("Failed to send start report: \(error)")
            }
        }
    }
    
    private func sendPauseReport(positionSeconds: Int) {
        Task {
            do {
                try await JFAPI.shared.reportPlaybackProgress(
                    for: item,
                    positionTicks: positionSeconds.toPositionTicks,
                    isPaused: true,
                    playSessionID: playSessionID
                )
            } catch {
                print("Failed to send pause report: \(error)")
            }
        }
    }
    
    private func sendResumeReport(positionSeconds: Int) {
        Task {
            do {
                try await JFAPI.shared.reportPlaybackProgress(
                    for: item,
                    positionTicks: positionSeconds.toPositionTicks,
                    isPaused: false,
                    playSessionID: playSessionID
                )
            } catch {
                print("Failed to send resume report: \(error)")
            }
        }
    }
    
    private func sendStopReport(positionSeconds: Int) {
        Task {
            do {
                try await JFAPI.shared.reportPlaybackStopped(
                    for: item,
                    positionTicks: positionSeconds.toPositionTicks,
                    playSessionID: playSessionID
                )
            } catch {
                print("Failed to send stop report: \(error)")
            }
        }
    }
    
    private func startProgressReporting(currentSeconds: Int) {
        stopProgressReporting()

        progressReportTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds

                guard !Task.isCancelled,
                      let self = self,
                      self.hasSentStart else { break }

                // Note: In a real implementation, we'd get the current position from the player
                // For now, we'll rely on the periodic updates from the view
                // This task mainly serves as a heartbeat to keep the session alive
            }
        }
    }

    /// Call this method periodically during playback to report progress
    func reportProgress(currentSeconds: Int) {
        guard hasSentStart else { return }

        Task {
            do {
                try await JFAPI.shared.reportPlaybackProgress(
                    for: item,
                    positionTicks: currentSeconds.toPositionTicks,
                    isPaused: false,
                    playSessionID: playSessionID
                )
            } catch {
                print("Failed to send progress report: \(error)")
            }
        }
    }
    
    private func stopProgressReporting() {
        progressReportTask?.cancel()
        progressReportTask = nil
    }
}
