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
        maxBitrate: Int = 20_000_000,
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

    /// Reports playback progress to the Jellyfin server
    /// - Parameters:
    ///   - item: The item being played
    ///   - positionTicks: Current playback position in ticks
    ///   - isPaused: Whether playback is currently paused
    static func reportPlaybackProgress(for item: BaseItemDto, positionTicks: Int64) async throws {
        let context = try getAPIContext()

        let progressInfo = PlaybackProgressInfo(
            itemID: item.id,
            mediaSourceID: item.id,
            positionTicks: Int(positionTicks)
        )

        let request = Paths.reportPlaybackProgress(progressInfo)
        _ = try await context.client.send(request)
    }
}
