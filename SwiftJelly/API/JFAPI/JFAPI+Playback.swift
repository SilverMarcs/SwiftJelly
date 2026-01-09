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
    /// Always requests transcoding with 1080p max resolution
    /// - Parameters:
    ///   - item: The BaseItemDto to get playback info for
    ///   - maxBitrate: Maximum streaming bitrate (default: 10 Mbps)
    ///   - subtitleStreamIndex: Optional subtitle stream index to enable (nil = no subtitles)
    /// - Returns: PlaybackInfoResponse with playback URL and session info
    static func getPlaybackInfo(
        for item: BaseItemDto,
        subtitleStreamIndex: Int? = nil,
        audioStreamIndex: Int? = nil,
        startPositionTicks: Int64? = nil,
        mediaSourceID: String? = nil
    ) async throws -> PlaybackInfoResponse {
        guard let itemID = item.id else {
            throw PlaybackError.missingItemID
        }
        
        let context = try getAPIContext()
        
        let deviceProfile = DeviceProfile.buildNativeProfile()
        
        let playbackInfoDto = PlaybackInfoDto(
            allowAudioStreamCopy: true,
            allowVideoStreamCopy: true,
            audioStreamIndex: audioStreamIndex,
            deviceProfile: deviceProfile,
            enableDirectPlay: true,
            enableDirectStream: true,
            enableTranscoding: true,
            mediaSourceID: mediaSourceID ?? item.mediaSources?.first?.id,
            startTimeTicks: startPositionTicks.map { Int($0) },
            subtitleStreamIndex: subtitleStreamIndex,
            userID: context.userID
        )
        
        let parameters = Paths.GetPostedPlaybackInfoParameters(
            userID: context.userID,
            startTimeTicks: startPositionTicks.map { Int($0) },
            audioStreamIndex: audioStreamIndex,
            subtitleStreamIndex: subtitleStreamIndex,
            mediaSourceID: mediaSourceID ?? item.mediaSources?.first?.id,
            enableDirectPlay: true,
            enableDirectStream: true,
            enableTranscoding: true,
            allowVideoStreamCopy: true,
            allowAudioStreamCopy: true
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

    static func reportPlaybackStart(
        itemID: String,
        mediaSourceID: String?,
        playSessionID: String?,
        playMethod: JellyfinAPI.PlayMethod?,
        audioStreamIndex: Int?,
        subtitleStreamIndex: Int?,
        canSeek: Bool,
        positionTicks: Int64?
    ) async {
        do {
            let context = try getAPIContext()
            var startInfo = PlaybackStartInfo()
            startInfo.canSeek = canSeek
            startInfo.itemID = itemID
            startInfo.mediaSourceID = mediaSourceID
            startInfo.audioStreamIndex = audioStreamIndex
            startInfo.subtitleStreamIndex = subtitleStreamIndex
            startInfo.positionTicks = positionTicks.map { Int($0) }
            startInfo.playMethod = playMethod
            startInfo.playSessionID = playSessionID
            startInfo.isPaused = false
            startInfo.isMuted = false
            let request = Paths.reportPlaybackStart(startInfo)
            _ = try await context.client.send(request)
        } catch {
            print("Failed to report playback start: \(error)")
        }
    }
    
    static func reportPlaybackProgress(
        itemID: String,
        mediaSourceID: String?,
        positionTicks: Int64,
        isPaused: Bool
    ) async {
        do {
            let context = try getAPIContext()
            var progressInfo = PlaybackProgressInfo()
            progressInfo.isPaused = isPaused
            progressInfo.itemID = itemID
            progressInfo.mediaSourceID = mediaSourceID
            progressInfo.positionTicks = Int(positionTicks)
            let request = Paths.reportPlaybackProgress(progressInfo)
            _ = try await context.client.send(request)
        } catch {
            print("Failed to report playback progress: \(error)")
        }
    }
    
    static func reportPlaybackStopped(
        itemID: String,
        mediaSourceID: String?,
        playSessionID: String?,
        positionTicks: Int64
    ) async {
        do {
            let context = try getAPIContext()
            var stopInfo = PlaybackStopInfo()
            stopInfo.itemID = itemID
            stopInfo.mediaSourceID = mediaSourceID
            stopInfo.positionTicks = Int(positionTicks)
            stopInfo.playSessionID = playSessionID
            let request = Paths.reportPlaybackStopped(stopInfo)
            _ = try await context.client.send(request)
        } catch {
            print("Failed to report playback stop: \(error)")
        }
    }
}
