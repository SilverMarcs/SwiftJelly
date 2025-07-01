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
            URLQueryItem(name: "api_key", value: context.server.accessToken)
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

    /// Generates a unique play session ID
    /// - Returns: A UUID string for the play session
    func generatePlaySessionID() -> String {
        return UUID().uuidString
    }

    /// Reports playback start to the Jellyfin server
    /// - Parameters:
    ///   - item: The item being played
    ///   - positionTicks: Current playback position in ticks
    ///   - playSessionID: The play session ID
    ///   - audioStreamIndex: Index of the audio stream
    ///   - subtitleStreamIndex: Index of the subtitle stream
    func reportPlaybackStart(for item: BaseItemDto, positionTicks: Int64, playSessionID: String, audioStreamIndex: Int? = nil, subtitleStreamIndex: Int? = nil) async throws {
        let context = try getAPIContext()

        let startInfo = PlaybackStartInfo(
            audioStreamIndex: audioStreamIndex,
            itemID: item.id,
            mediaSourceID: item.id,
            playbackStartTimeTicks: Int(Date().timeIntervalSince1970) * 10_000_000,
            positionTicks: Int(positionTicks),
            sessionID: playSessionID,
            subtitleStreamIndex: subtitleStreamIndex
        )

        let request = Paths.reportPlaybackStart(startInfo)
        _ = try await context.client.send(request)
//        print("Sent playback start report for \(item.name ?? "Unknown")")
    }

    /// Reports playback progress to the Jellyfin server
    /// - Parameters:
    ///   - item: The item being played
    ///   - positionTicks: Current playback position in ticks
    ///   - isPaused: Whether playback is currently paused
    ///   - playSessionID: The play session ID
    ///   - audioStreamIndex: Index of the audio stream
    ///   - subtitleStreamIndex: Index of the subtitle stream
    func reportPlaybackProgress(for item: BaseItemDto, positionTicks: Int64, isPaused: Bool, playSessionID: String, audioStreamIndex: Int? = nil, subtitleStreamIndex: Int? = nil) async throws {
        let context = try getAPIContext()

        let progressInfo = PlaybackProgressInfo(
            audioStreamIndex: audioStreamIndex,
            isPaused: isPaused,
            itemID: item.id,
            mediaSourceID: item.id,
            playSessionID: playSessionID,
            positionTicks: Int(positionTicks),
            sessionID: playSessionID,
            subtitleStreamIndex: subtitleStreamIndex
        )

        let request = Paths.reportPlaybackProgress(progressInfo)
        _ = try await context.client.send(request)
//        print("Sent playback progress report for \(item.name ?? "Unknown") at \(positionTicks / 10_000_000)s")
    }

    /// Reports playback stop to the Jellyfin server
    /// - Parameters:
    ///   - item: The item that was being played
    ///   - positionTicks: Final playback position in ticks
    ///   - playSessionID: The play session ID
    func reportPlaybackStopped(for item: BaseItemDto, positionTicks: Int64, playSessionID: String) async throws {
        let context = try getAPIContext()

        let stopInfo = PlaybackStopInfo(
            itemID: item.id,
            mediaSourceID: item.id,
            positionTicks: Int(positionTicks),
            sessionID: playSessionID
        )

        let request = Paths.reportPlaybackStopped(stopInfo)
        _ = try await context.client.send(request)
//        print("Sent playback stop report for \(item.name ?? "Unknown")")
    }
}
