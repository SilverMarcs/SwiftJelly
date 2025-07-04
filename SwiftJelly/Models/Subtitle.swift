import Foundation
import JellyfinAPI
import VLCUI

/// A unified subtitle type that handles subtitle tracks from VLC
struct Subtitle: Equatable, Identifiable {
    let id = UUID()
    let index: Int
    let title: String
    
    /// Create from VLC MediaTrack
    init(from mediaTrack: MediaTrack) {
        self.index = mediaTrack.index
        self.title = mediaTrack.title.isEmpty ? "Track \(mediaTrack.index + 1)" : mediaTrack.title
    }
    
    init(index: Int, title: String) {
        self.index = index
        self.title = title
    }
}
