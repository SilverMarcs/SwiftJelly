import Foundation
import JellyfinAPI
import VLCUI
import Get

extension JFAPI {
    /// Fetches all subtitle streams (both embedded and external) for a media item from Jellyfin server
    /// This calls getPostedPlaybackInfo to get the proper external subtitle delivery URLs
    /// - Parameter item: The BaseItemDto to get subtitle streams for
    /// - Returns: Array of MediaStream subtitle tracks with properly populated deliveryURL
    func getAllSubtitleStreams(for item: BaseItemDto) async throws -> [MediaStream] {
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
        
        // Get subtitle streams from the response (they will have proper deliveryURL populated)
        guard let mediaSources = response.value.mediaSources else { return [] }
        
        var subtitleStreams: [MediaStream] = []
        for mediaSource in mediaSources {
            if let streams = mediaSource.mediaStreams {
                let subtitles = streams.filter { $0.type == .subtitle }
                subtitleStreams.append(contentsOf: subtitles)
            }
        }
        
        return subtitleStreams
    }
    
    /// Gets combined subtitle tracks (both embedded and external)
    /// - Parameters:
    ///   - item: The BaseItemDto to get subtitles for
    ///   - embeddedTracks: VLC MediaTrack array from embedded subtitles
    /// - Returns: Array of UnifiedSubtitle containing both embedded and external subtitles
    func getCombinedSubtitles(for item: BaseItemDto, embeddedTracks: [MediaTrack]) async throws -> [UnifiedSubtitle] {
        // Get all subtitle streams from Jellyfin (includes both embedded and external)
        let allStreams = try await getAllSubtitleStreams(for: item)
        
        // Convert Jellyfin streams to UnifiedSubtitle
        // External subtitles will have deliveryURL, embedded ones won't
        let jellyfinSubtitles = allStreams.map { UnifiedSubtitle(from: $0) }
        
        // For embedded subtitles, prefer VLC MediaTrack info when available
        // VLC provides better track information for embedded subtitles
        var combinedSubtitles: [UnifiedSubtitle] = []
        
        // Add VLC embedded tracks first (they have better info)
        combinedSubtitles.append(contentsOf: embeddedTracks.map { UnifiedSubtitle(from: $0) })
        
        // Add external subtitles from Jellyfin
        let externalSubtitles = jellyfinSubtitles.filter { $0.isExternal }
        combinedSubtitles.append(contentsOf: externalSubtitles)
        
        return combinedSubtitles
    }
    
    /// Creates VLC PlaybackChildren for external subtitles
    /// - Parameters:
    ///   - subtitles: Array of UnifiedSubtitle containing external subtitles
    /// - Returns: Array of VLC PlaybackChild for external subtitles
    func createSubtitlePlaybackChildren(from subtitles: [UnifiedSubtitle]) throws -> [VLCVideoPlayer.PlaybackChild] {
        let context = try getAPIContext()
        
        return subtitles.compactMap { subtitle in
            subtitle.asPlaybackChild(client: context.client)
        }
    }
}
