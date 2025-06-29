//
//  JFAPI+Playback.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 29/06/2025.
//

import Foundation
import JellyfinAPI

extension JFAPI {
    /// Generates a playback URL for a media item
    /// - Parameter item: The BaseItemDto to generate a playback URL for
    /// - Returns: URL for streaming the media item, or nil if unable to generate
    func getPlaybackURL(for item: BaseItemDto) throws -> URL? {
        guard let id = item.id else { return nil }
        let context = try getAPIContext()

        var components = URLComponents(url: context.server.url, resolvingAgainstBaseURL: false)
        components?.path = "/Videos/\(id)/stream"
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "Static", value: "true"),
            URLQueryItem(name: "mediaSourceId", value: id),
            URLQueryItem(name: "api_key", value: context.user.accessToken)
        ]
        queryItems.append(URLQueryItem(name: "deviceId", value: "deviceId"))
        components?.queryItems = queryItems
        return components?.url
    }

    /// Gets the start time in seconds for a media item based on playback position
    /// - Parameter item: The BaseItemDto to get start time for
    /// - Returns: Start time in seconds
    func getStartTimeSeconds(for item: BaseItemDto) -> Int {
        guard let ticks = item.userData?.playbackPositionTicks else { return 0 }
        return Int(ticks / 10_000_000)
    }

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
