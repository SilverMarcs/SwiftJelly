//
//  JFAPI+Playback.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 29/06/2025.
//

import Get
import Foundation
import JellyfinAPI

extension JFAPI {
    
    /// Gets playback info with device profile for AVPlayer-compatible streaming
    /// This tells Jellyfin to transcode if the media is not directly playable
    /// - Parameters:
    ///   - item: The BaseItemDto to get playback info for
    ///   - maxBitrate: Maximum streaming bitrate (default: 120 Mbps)
    ///   - subtitleStreamIndex: Optional subtitle stream index to enable (nil = no subtitles)
    /// - Returns: PlaybackInfoResponse with playback URL and session info
    static func getPlaybackInfo(
        for item: BaseItemDto,
        maxBitrate: Int = 10_000_000,
        subtitleStreamIndex: Int? = nil
    ) async throws -> PlaybackInfoResponse {
        guard let itemID = item.id else {
            throw PlaybackError.missingItemID
        }
        
        let context = try getAPIContext()
        
        // Build device profile for native AVPlayer
        let deviceProfile = DeviceProfile.buildNativeProfile(maxBitrate: maxBitrate)
        
        // Create playback info request with device profile
        let playbackInfoDto = PlaybackInfoDto(deviceProfile: deviceProfile)
        
        let parameters = Paths.GetPostedPlaybackInfoParameters(
            userID: context.userID,
            maxStreamingBitrate: maxBitrate,
            subtitleStreamIndex: subtitleStreamIndex, mediaSourceID: item.mediaSources?.first?.id
        )
        
        let request = Paths.getPostedPlaybackInfo(
            itemID: itemID,
            parameters: parameters,
            playbackInfoDto
        )
        
        let response = try await context.client.send(request)
        
        return try PlaybackInfoResponse.from(
            response: response.value,
            item: item,
            client: context.client
        )
    }
    
    /// Generates a playback URL for a media item (legacy method - prefer getPlaybackInfo)
    /// - Parameter item: The BaseItemDto to generate a playback URL for
    /// - Returns: URL for streaming the media item, or nil if unable to generate
    static func getPlaybackURL(for item: BaseItemDto) throws -> URL? {
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

    /// Generates a unique play session ID
    /// - Returns: A UUID string for the play session
    static func generatePlaySessionID() -> String {
        return UUID().uuidString
    }

    /// Reports playback start to the Jellyfin server
    /// - Parameters:
    ///   - item: The item being played
    ///   - positionTicks: Current playback position in ticks
    ///   - playSessionID: The play session ID
    ///   - audioStreamIndex: Index of the audio stream
    ///   - subtitleStreamIndex: Index of the subtitle stream
    static func reportPlaybackStart(for item: BaseItemDto, positionTicks: Int64, playSessionID: String, audioStreamIndex: Int? = nil, subtitleStreamIndex: Int? = nil) async throws {
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
    static func reportPlaybackProgress(for item: BaseItemDto, positionTicks: Int64, isPaused: Bool, playSessionID: String, audioStreamIndex: Int? = nil, subtitleStreamIndex: Int? = nil) async throws {
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
    static func reportPlaybackStopped(for item: BaseItemDto, positionTicks: Int64, playSessionID: String) async throws {
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
