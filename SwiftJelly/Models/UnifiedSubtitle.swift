import Foundation
import JellyfinAPI
import VLCUI

/// A unified subtitle type that handles both embedded (VLC MediaTrack) and external (Jellyfin MediaStream) subtitles
struct UnifiedSubtitle: Equatable, Identifiable {
    let id = UUID()
    let index: Int
    let title: String
    let isExternal: Bool
    let deliveryURL: String?
    
    /// Create from VLC MediaTrack (embedded subtitle)
    init(from mediaTrack: MediaTrack) {
        self.index = mediaTrack.index
        self.title = mediaTrack.title.isEmpty ? "Track \(mediaTrack.index + 1)" : mediaTrack.title
        self.isExternal = false
        self.deliveryURL = nil
    }
    
    /// Create from Jellyfin MediaStream (external subtitle)
    init(from mediaStream: MediaStream) {
        print("mediastream url: \(mediaStream.deliveryURL ?? "nil")")
        self.index = mediaStream.index ?? -1
        self.title = mediaStream.displayTitle ?? mediaStream.language ?? "Subtitle Track \((mediaStream.index ?? 0) + 1)"
        // External subtitles have a deliveryURL, embedded ones don't
//        self.isExternal = mediaStream.deliveryURL != nil
        self.isExternal = true
        self.deliveryURL = mediaStream.deliveryURL
    }
    
    init(index: Int, title: String, isExternal: Bool, deliveryURL: String? = nil) {
        self.index = index
        self.title = title
        self.isExternal = isExternal
        self.deliveryURL = deliveryURL
    }

    /// Convert external subtitle to VLC PlaybackChild
    func asPlaybackChild(client: JellyfinClient) -> VLCVideoPlayer.PlaybackChild? {
        guard isExternal, let deliveryURL = deliveryURL else { return nil }
        
        guard let fullURL = client.fullURL(with: deliveryURL) else { return nil }
        
        return VLCVideoPlayer.PlaybackChild(
            url: fullURL,
            type: .subtitle,
            enforce: false
        )
    }
}
