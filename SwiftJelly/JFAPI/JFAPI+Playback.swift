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
        maxBitrate: Int = 15_000_000,
        subtitleStreamIndex: Int? = nil,
        audioStreamIndex: Int? = nil,
        startPositionTicks: Int64? = nil
    ) async throws -> PlaybackInfoResponse {
        guard let itemID = item.id else {
            throw PlaybackError.missingItemID
        }
        
        let context = try getAPIContext()
        
        let deviceProfile = DeviceProfile.buildNativeProfile(maxBitrate: maxBitrate)
        
        let playbackInfoDto = PlaybackInfoDto(
            allowAudioStreamCopy: true,
            allowVideoStreamCopy: true,
            audioStreamIndex: audioStreamIndex,
            deviceProfile: deviceProfile,
            enableDirectPlay: true,
            enableDirectStream: true,
            enableTranscoding: true,
            maxStreamingBitrate: maxBitrate,
            mediaSourceID: item.mediaSources?.first?.id,
            startTimeTicks: startPositionTicks.map { Int($0) },
            subtitleStreamIndex: subtitleStreamIndex,
            userID: context.userID
        )
        
        let parameters = Paths.GetPostedPlaybackInfoParameters(
            userID: context.userID,
            maxStreamingBitrate: maxBitrate,
            startTimeTicks: startPositionTicks.map { Int($0) },
            audioStreamIndex: audioStreamIndex,
            subtitleStreamIndex: subtitleStreamIndex,
            mediaSourceID: item.mediaSources?.first?.id,
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
            let payload = PlaybackStartInfoPayload(
                canSeek: canSeek,
                itemId: itemID,
                mediaSourceId: mediaSourceID,
                audioStreamIndex: audioStreamIndex,
                subtitleStreamIndex: subtitleStreamIndex,
                positionTicks: positionTicks,
                playMethod: playMethod,
                playSessionId: playSessionID
            )
            let request = Request<Void>(
                path: "/Sessions/Playing",
                method: "POST",
                body: payload,
                id: "ReportPlaybackStart"
            )
            _ = try await context.client.send(request)
        } catch {
            print("Failed to report playback start: \(error)")
        }
    }
    
    static func reportPlaybackProgress(
        itemID: String,
        mediaSourceID: String?,
        playSessionID: String?,
        playMethod: JellyfinAPI.PlayMethod?,
        audioStreamIndex: Int?,
        subtitleStreamIndex: Int?,
        positionTicks: Int64,
        canSeek: Bool,
        isPaused: Bool
    ) async {
        do {
            let context = try getAPIContext()
            var progressInfo = PlaybackProgressInfo()
            progressInfo.canSeek = canSeek
            progressInfo.isPaused = isPaused
            progressInfo.itemID = itemID
            progressInfo.mediaSourceID = mediaSourceID
            progressInfo.playMethod = playMethod
            progressInfo.playSessionID = playSessionID
            progressInfo.audioStreamIndex = audioStreamIndex
            progressInfo.subtitleStreamIndex = subtitleStreamIndex
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
            let payload = PlaybackStopInfoPayload(
                itemId: itemID,
                mediaSourceId: mediaSourceID,
                positionTicks: positionTicks,
                playSessionId: playSessionID
            )
            let request = Request<Void>(
                path: "/Sessions/Playing/Stopped",
                method: "POST",
                body: payload,
                id: "ReportPlaybackStopped"
            )
            _ = try await context.client.send(request)
        } catch {
            print("Failed to report playback stop: \(error)")
        }
    }
}

private struct PlaybackStartInfoPayload: Encodable {
    var canSeek: Bool
    var itemId: String
    var mediaSourceId: String?
    var audioStreamIndex: Int?
    var subtitleStreamIndex: Int?
    var isPaused: Bool = false
    var isMuted: Bool = false
    var positionTicks: Int64?
    var playbackStartTimeTicks: Int64?
    var playMethod: JellyfinAPI.PlayMethod?
    var playSessionId: String?
    
    enum CodingKeys: String, CodingKey {
        case canSeek = "CanSeek"
        case itemId = "ItemId"
        case mediaSourceId = "MediaSourceId"
        case audioStreamIndex = "AudioStreamIndex"
        case subtitleStreamIndex = "SubtitleStreamIndex"
        case isPaused = "IsPaused"
        case isMuted = "IsMuted"
        case positionTicks = "PositionTicks"
        case playbackStartTimeTicks = "PlaybackStartTimeTicks"
        case playMethod = "PlayMethod"
        case playSessionId = "PlaySessionId"
    }
}

private struct PlaybackStopInfoPayload: Encodable {
    var itemId: String
    var mediaSourceId: String?
    var positionTicks: Int64
    var playSessionId: String?
    
    enum CodingKeys: String, CodingKey {
        case itemId = "ItemId"
        case mediaSourceId = "MediaSourceId"
        case positionTicks = "PositionTicks"
        case playSessionId = "PlaySessionId"
    }
}
