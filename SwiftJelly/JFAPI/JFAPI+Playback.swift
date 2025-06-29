//
//  JFAPI+Playback.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 29/06/2025.
//

import Foundation
import JellyfinAPI

extension JFAPI {
    /// Reports playback progress to the Jellyfin server
    /// - Parameters:
    ///   - item: The item being played
    ///   - positionTicks: Current playback position in ticks
    ///   - isPaused: Whether playback is currently paused
    func reportPlaybackProgress(for item: BaseItemDto, positionTicks: Int64, isPaused: Bool) async throws {
        // TODO: Implement playback progress reporting
    }
    /// Reports playback stop to the Jellyfin server
    /// - Parameters:
    ///   - item: The item that was being played
    ///   - positionTicks: Final playback position in ticks
    func reportPlaybackStopped(for item: BaseItemDto, positionTicks: Int64) async throws {
        // TODO: Implement playback stopped reporting
    }
}
