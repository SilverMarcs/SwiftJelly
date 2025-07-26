//
//  JFAPI+Subtitles.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 26/07/2025.
//

import Foundation
import JellyfinAPI
import VLCUI

extension JFAPI {
    /// Fetches external subtitle streams for a media item from Jellyfin server
    /// - Parameter item: The BaseItemDto to get subtitle streams for
    /// - Returns: Array of MediaStream subtitle tracks with deliveryURL
    static func getExternalSubtitleStreams(for item: BaseItemDto) async throws -> [MediaStream] {
//        guard let itemId = item.id else { return [] }
//        
//        let context = try getAPIContext()
//        
//        let playbackInfoRequest = PlaybackInfoDto(
//            deviceProfile: .vlcProfile,
//            userID: context.user.id,
//            maxStreamingBitrate: 100_000_000
//        )
//        
//        let request = Paths.getPostedPlaybackInfo(
//            itemID: itemId,
//            userID: context.user.id,
//            maxStreamingBitrate: 100_000_000,
//            playbackInfoDto: playbackInfoRequest
//        )
//        
//        let response = try await context.client.send(request)
//        
//        // Get only external subtitle streams (those with deliveryURL)
//        guard let mediaSources = response.value.mediaSources else { return [] }
//        
//        var externalSubtitles: [MediaStream] = []
//        for mediaSource in mediaSources {
//            if let streams = mediaSource.mediaStreams {
//                let subtitles = streams.filter { $0.type == .subtitle && $0.deliveryURL != nil }
//                externalSubtitles.append(contentsOf: subtitles)
//            }
//        }
//        
//        return externalSubtitles
        return []
    }
    
    /// Creates VLC PlaybackChildren for external subtitles
    /// - Parameter item: The BaseItemDto to get external subtitles for
    /// - Returns: Array of VLC PlaybackChild for external subtitles
    static func createExternalSubtitlePlaybackChildren(for item: BaseItemDto) async throws -> [VLCVideoPlayer.PlaybackChild] {
        let context = try getAPIContext()
        let externalStreams = try await getExternalSubtitleStreams(for: item)
        
        return externalStreams.compactMap { stream in
            guard let deliveryURL = stream.deliveryURL,
                  let fullURL = context.client.fullURL(with: deliveryURL) else { return nil }
            
            return VLCVideoPlayer.PlaybackChild(
                url: fullURL,
                type: .subtitle,
                enforce: false
            )
        }
    }
}
