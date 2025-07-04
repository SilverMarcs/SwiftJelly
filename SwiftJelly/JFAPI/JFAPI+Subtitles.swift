import Foundation
import JellyfinAPI
import VLCUI
import Get

extension JFAPI {
    /// Fetches external subtitle streams for a media item from Jellyfin server
    /// - Parameter item: The BaseItemDto to get subtitle streams for
    /// - Returns: Array of MediaStream subtitle tracks with deliveryURL
    func getExternalSubtitleStreams(for item: BaseItemDto) async throws -> [MediaStream] {
        guard let itemId = item.id else { return [] }
        
        let context = try getAPIContext()
        
        // Get the first media source from the item to use its ID
        guard let mediaSources = item.mediaSources,
              let firstMediaSource = mediaSources.first,
              let mediaSourceId = firstMediaSource.id else {
            return []
        }
        
        // Create a device profile that supports external subtitles
        let deviceProfile = DeviceProfile.createBasicVLCProfile(maxBitrate: 100_000_000) // 100 Mbps max
        let playbackInfo = PlaybackInfoDto(deviceProfile: deviceProfile)
        
        let playbackInfoParameters = Paths.GetPostedPlaybackInfoParameters(
            userID: context.server.jellyfinUserID ?? "",
            maxStreamingBitrate: 100_000_000,
            mediaSourceID: mediaSourceId
        )
        
        let request = Paths.getPostedPlaybackInfo(
            itemID: itemId,
            parameters: playbackInfoParameters,
            playbackInfo
        )
        
        let response = try await context.client.send(request)
        
        // Get only external subtitle streams (those with deliveryURL)
        guard let mediaSources = response.value.mediaSources else { return [] }
        
        var externalSubtitles: [MediaStream] = []
        for mediaSource in mediaSources {
            if let streams = mediaSource.mediaStreams {
                let subtitles = streams.filter { $0.type == .subtitle && $0.deliveryURL != nil }
                externalSubtitles.append(contentsOf: subtitles)
            }
        }
        
        return externalSubtitles
    }
    
    /// Creates VLC PlaybackChildren for external subtitles
    /// - Parameter item: The BaseItemDto to get external subtitles for
    /// - Returns: Array of VLC PlaybackChild for external subtitles
    func createExternalSubtitlePlaybackChildren(for item: BaseItemDto) async throws -> [VLCVideoPlayer.PlaybackChild] {
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
