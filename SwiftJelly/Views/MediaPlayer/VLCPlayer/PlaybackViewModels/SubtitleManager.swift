import Foundation
import JellyfinAPI
import VLCUI

@Observable class SubtitleManager {
    @ObservationIgnored private let item: BaseItemDto
    var isLoading: Bool = false
    var availableSubtitles: [MediaTrack] = []
    var selectedSubtitleIndex: Int = -1
    
    private var vlcProxy: VLCVideoPlayer.Proxy?
    private var externalSubtitleChildren: [VLCVideoPlayer.PlaybackChild] = []
    
    init(item: BaseItemDto) {
        self.item = item
    }
    
    func setVLCProxy(_ proxy: VLCVideoPlayer.Proxy) {
        self.vlcProxy = proxy
    }
    
    func getPlaybackChildren() -> [VLCVideoPlayer.PlaybackChild] {
        return externalSubtitleChildren
    }
    
    func updateFromPlaybackInfo(_ info: VLCVideoPlayer.PlaybackInformation) {
        // Update current subtitle selection based on VLC state
        let currentTrack = info.currentSubtitleTrack
        selectedSubtitleIndex = currentTrack.index
    }
    
    func loadSubtitlesFromVLC(tracks: [MediaTrack]) {
        availableSubtitles = tracks
    }
    
    func loadExternalSubtitles() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            externalSubtitleChildren = try await JFAPI.createExternalSubtitlePlaybackChildren(for: item)
            print("Loaded \(externalSubtitleChildren.count) external subtitle streams")
        } catch {
            print("Failed to load external subtitles: \(error)")
        }
    }
    
    func selectSubtitle(at index: Int) {
        selectedSubtitleIndex = index
        if index == -1 {
            vlcProxy?.setSubtitleTrack(.absolute(-1))
        } else {
            vlcProxy?.setSubtitleTrack(.absolute(index))
        }
    }
}
