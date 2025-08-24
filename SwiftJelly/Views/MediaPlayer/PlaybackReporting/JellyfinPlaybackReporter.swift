//
//  JellyfinPlaybackReporter.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 24/08/2025.
//

import Foundation
import JellyfinAPI

/// Handles playback session reporting to Jellyfin server
class JellyfinPlaybackReporter: PlaybackReporterProtocol {
    let playSessionID: String
    private let item: BaseItemDto
    private var hasSentStart: Bool = false
    
    var hasStarted: Bool {
        hasSentStart
    }
    
    init(item: BaseItemDto) {
        self.item = item
        self.playSessionID = JFAPI.generatePlaySessionID()
    }
    
    /// Starts the playback session and sends start report
    func reportStart(positionSeconds: Int) {
        guard !hasSentStart else { return }
        hasSentStart = true
        
        Task {
            do {
                try await JFAPI.reportPlaybackStart(
                    for: item,
                    positionTicks: positionSeconds.toPositionTicks,
                    playSessionID: playSessionID
                )
            } catch {
                print("Failed to send start report: \(error)")
            }
        }
    }
    
    /// Reports playback pause
    func reportPause(positionSeconds: Int) {
        guard hasSentStart else { return }
        
        Task {
            do {
                try await JFAPI.reportPlaybackProgress(
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
    
    /// Reports playback resume
    func reportResume(positionSeconds: Int) {
        guard hasSentStart else { return }
        
        Task {
            do {
                try await JFAPI.reportPlaybackProgress(
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
    
    /// Reports playback progress (periodic updates)
    func reportProgress(positionSeconds: Int, isPaused: Bool) {
        guard hasSentStart else { return }
        
        Task {
            do {
                try await JFAPI.reportPlaybackProgress(
                    for: item,
                    positionTicks: positionSeconds.toPositionTicks,
                    isPaused: isPaused,
                    playSessionID: playSessionID
                )
            } catch {
                print("Failed to send progress report: \(error)")
            }
        }
    }
    
    /// Reports playback stop
    func reportStop(positionSeconds: Int) {
        guard hasSentStart else { return }
        
        Task {
            do {
                try await JFAPI.reportPlaybackStopped(
                    for: item,
                    positionTicks: positionSeconds.toPositionTicks,
                    playSessionID: playSessionID
                )
            } catch {
                print("Failed to send stop report: \(error)")
            }
        }
    }
}
