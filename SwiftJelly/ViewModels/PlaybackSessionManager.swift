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
    private let item: BaseItemDto

    init(item: BaseItemDto) {
        self.item = item
        self.playSessionID = JFAPI.shared.generatePlaySessionID()
    }

    // MARK: - Public Methods

    /// Starts the playback session and sends start report
    func startPlayback(at positionSeconds: Int) {
        guard !hasSentStart else { return }
        hasSentStart = true
        sendStartReport(positionSeconds: positionSeconds)
    }

    /// Reports playback pause
    func pausePlayback(at positionSeconds: Int) {
        sendPauseReport(positionSeconds: positionSeconds)
    }

    /// Reports playback resume
    func resumePlayback(at positionSeconds: Int) {
        sendResumeReport(positionSeconds: positionSeconds)
    }

    /// Reports playback stop and cleans up session
    func stopPlayback(at positionSeconds: Int) {
        if hasSentStart {
            sendStopReport(positionSeconds: positionSeconds)
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
    
    // No periodic reporting or progress task anymore
}
