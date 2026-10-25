//
//  JFAPI+Playback.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 29/06/2025.
//

import OSLog
import Get
import Foundation
import JellyfinAPI

extension JFAPI {
    
    /// Gets playback info with device profile for AVPlayer-compatible streaming
    /// - Parameters:
    ///   - item: The BaseItemDto to get playback info for
    ///   - subtitleStreamIndex: Optional subtitle stream index to enable (nil = no subtitles)
    /// - Returns: PlaybackInfoResponse with playback URL and session info
    static func getPlaybackInfo(
        for item: BaseItemDto,
        subtitleStreamIndex: Int? = nil,
        audioStreamIndex: Int? = nil,
        startPositionTicks: Int64? = nil,
        mediaSourceID: String? = nil,
        context suppliedContext: APIContext? = nil
    ) async throws -> PlaybackInfoResponse {
        guard let itemID = item.id else {
            throw PlaybackError.missingItemID
        }
        
        let context = try suppliedContext ?? getAPIContext()
        
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
            client: context.client,
            audioStreamIndex: audioStreamIndex
        )
    }

    static func reportPlaybackStart(context: APIContext, state: PlaybackProgressInfo) async {
        var info = PlaybackStartInfo()
        info.itemID = state.itemID
        info.mediaSourceID = state.mediaSourceID
        info.playSessionID = state.playSessionID
        info.playMethod = state.playMethod
        info.audioStreamIndex = state.audioStreamIndex
        info.subtitleStreamIndex = state.subtitleStreamIndex
        info.positionTicks = state.positionTicks
        info.isPaused = state.isPaused
        info.isMuted = state.isMuted
        info.canSeek = state.canSeek
        do { _ = try await context.client.send(Paths.reportPlaybackStart(info)) }
        catch { playbackLogger.error("Playback start report failed: \(String(describing: type(of: error)), privacy: .public)") }
    }

    static func reportPlaybackProgress(context: APIContext, state: PlaybackProgressInfo) async {
        do { _ = try await context.client.send(Paths.reportPlaybackProgress(state)) }
        catch { playbackLogger.error("Playback progress report failed: \(String(describing: type(of: error)), privacy: .public)") }
    }

    static func reportPlaybackStopped(context: APIContext, state: PlaybackProgressInfo) async {
        var info = PlaybackStopInfo()
        info.itemID = state.itemID
        info.mediaSourceID = state.mediaSourceID
        info.playSessionID = state.playSessionID
        info.positionTicks = state.positionTicks
        do { _ = try await context.client.send(Paths.reportPlaybackStopped(info)) }
        catch { playbackLogger.error("Playback stop report failed: \(String(describing: type(of: error)), privacy: .public)") }
    }

    static func stopPlaybackEncodings(context: APIContext, sessionIDs: [String]) async {
        for id in Set(sessionIDs) {
            let request = Request<Void>(path: "/Videos/ActiveEncodings", method: .delete, query: [("deviceId", context.server.id), ("playSessionId", id)])
            do { _ = try await context.client.send(request) }
            catch { playbackLogger.error("Encoding cleanup failed: \(String(describing: type(of: error)), privacy: .public)") }
        }
    }

    private static let playbackLogger = Logger(subsystem: "com.SilverMarcs.SwiftJelly", category: "Playback")
}
