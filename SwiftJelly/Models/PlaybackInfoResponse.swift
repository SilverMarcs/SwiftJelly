//
//  PlaybackInfoResponse.swift
//  SwiftJelly
//

import Foundation
import JellyfinAPI

struct PlaybackInfoResponse {
    let playbackURL: URL
    let mediaSource: MediaSourceInfo
    let playMethod: PlayMethod
    let playSessionId: String?
    
    enum PlayMethod {
        case directPlay
        case transcode
    }
}

extension PlaybackInfoResponse {
    
    /// Creates a PlaybackInfoResponse from the getPlaybackInfo API response
    static func from(
        response: PlaybackInfoResponse_JellyfinAPI,
        item: BaseItemDto,
        client: JellyfinClient
    ) throws -> PlaybackInfoResponse {
        
        guard let mediaSources = response.mediaSources,
              let mediaSource = mediaSources.first else {
            throw PlaybackError.noMediaSources
        }
        
        let playbackURL: URL
        let playMethod: PlayMethod
        
        // Check if we need to transcode
        if let transcodingURL = mediaSource.transcodingURL {
            guard let fullURL = client.fullURL(with: transcodingURL) else {
                throw PlaybackError.invalidTranscodeURL
            }
            playbackURL = fullURL
            playMethod = .transcode
        } else {
            // Direct play
            guard let itemID = item.id else {
                throw PlaybackError.missingItemID
            }
            
            let streamParameters = Paths.GetVideoStreamParameters(
                isStatic: true,
                tag: item.etag,
                playSessionID: nil,
                mediaSourceID: mediaSource.id
            )
            
            let streamRequest = Paths.getVideoStream(
                itemID: itemID,
                parameters: streamParameters
            )
            
            guard let fullURL = client.fullURL(with: streamRequest) else {
                throw PlaybackError.invalidStreamURL
            }
            
            playbackURL = fullURL
            playMethod = .directPlay
        }

        return PlaybackInfoResponse(
            playbackURL: playbackURL,
            mediaSource: mediaSource,
            playMethod: playMethod,
            playSessionId: response.playSessionID
        )
    }
}

enum PlaybackError: Error, LocalizedError {
    case noMediaSources
    case invalidTranscodeURL
    case invalidStreamURL
    case missingItemID
    
    var errorDescription: String? {
        switch self {
        case .noMediaSources:
            return "No media sources available"
        case .invalidTranscodeURL:
            return "Invalid transcode URL"
        case .invalidStreamURL:
            return "Invalid stream URL"
        case .missingItemID:
            return "Missing item ID"
        }
    }
}

// Type alias to avoid confusion with our custom type
typealias PlaybackInfoResponse_JellyfinAPI = JellyfinAPI.PlaybackInfoResponse
