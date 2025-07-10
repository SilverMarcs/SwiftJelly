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
    private let reporter: PlaybackReporter

    init(item: BaseItemDto) {
        self.reporter = PlaybackReporter(item: item)
        self.playSessionID = reporter.playSessionID
    }

    // MARK: - Public Methods

    /// Starts the playback session and sends start report
    func startPlayback(at positionSeconds: Int) {
        guard !hasSentStart else { return }
        hasSentStart = true
        reporter.reportStart(positionSeconds: positionSeconds)
    }

    /// Reports playback pause
    func pausePlayback(at positionSeconds: Int) {
        reporter.reportPause(positionSeconds: positionSeconds)
    }

    /// Reports playback resume
    func resumePlayback(at positionSeconds: Int) {
        reporter.reportResume(positionSeconds: positionSeconds)
    }

    /// Reports playback stop and cleans up session
    func stopPlayback(at positionSeconds: Int) {
        reporter.reportStop(positionSeconds: positionSeconds)
    }
}
