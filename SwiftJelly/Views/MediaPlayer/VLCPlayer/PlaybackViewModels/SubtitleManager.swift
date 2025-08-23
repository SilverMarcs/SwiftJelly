import Foundation
import JellyfinAPI
import VLCUI

@Observable class SubtitleManager {
    var availableSubtitles: [MediaTrack] = []
    var selectedSubtitleIndex: Int = -1
    
    private let vlcProxy: VLCVideoPlayer.Proxy
    
    init(vlcProxy: VLCVideoPlayer.Proxy) {
        self.vlcProxy = vlcProxy
    }
    
    func updateFromPlaybackInfo(_ info: VLCVideoPlayer.PlaybackInformation) {
        // Update current subtitle selection based on VLC state
        let currentTrack = info.currentSubtitleTrack
        selectedSubtitleIndex = currentTrack.index
    }
    
    func loadSubtitlesFromVLC(tracks: [MediaTrack]) {
        availableSubtitles = tracks
    }
    
    func selectSubtitle(at index: Int) {
        selectedSubtitleIndex = index
        if index == -1 {
            vlcProxy.setSubtitleTrack(.absolute(-1))
        } else {
            vlcProxy.setSubtitleTrack(.absolute(index))
        }
    }
}
