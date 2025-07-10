import Foundation
import JellyfinAPI
import VLCUI
import Combine

class SubtitleManager: ObservableObject {
    @Published var availableSubtitles: [Subtitle] = []
    @Published var selectedSubtitle: Subtitle?
    @Published var isLoading = false
    
    private let item: BaseItemDto
    private var vlcProxy: VLCVideoPlayer.Proxy?
    private var playbackChildren: [VLCVideoPlayer.PlaybackChild] = []
    
    init(item: BaseItemDto) {
        self.item = item
    }
    
    func setVLCProxy(_ proxy: VLCVideoPlayer.Proxy) {
        self.vlcProxy = proxy
    }
    
    /// Load external subtitles before VLC initialization
    func loadExternalSubtitles() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            playbackChildren = try await JFAPI.shared.createExternalSubtitlePlaybackChildren(for: item)
        } catch {
            print("Failed to load external subtitles: \(error)")
            playbackChildren = []
        }
    }
    
    /// Load all subtitles from VLC track info (includes both embedded and external loaded as PlaybackChildren)
    func loadSubtitlesFromVLC(tracks: [MediaTrack]) {
        availableSubtitles = tracks.map { Subtitle(from: $0) }
    }
    
    /// Select a subtitle track
    func selectSubtitle(_ subtitle: Subtitle) {
        selectedSubtitle = subtitle
        
        guard let proxy = vlcProxy else { return }
        proxy.setSubtitleTrack(.absolute(subtitle.index))
    }
    
    /// Get PlaybackChildren for VLC configuration
    func getPlaybackChildren() -> [VLCVideoPlayer.PlaybackChild] {
        return playbackChildren
    }
    
    /// Update when VLC playback info changes
    func updateFromPlaybackInfo(_ info: VLCVideoPlayer.PlaybackInformation) {
        if let matchingSubtitle = availableSubtitles.first(where: { $0.index == info.currentSubtitleTrack.index }) {
            selectedSubtitle = matchingSubtitle
        }
    }
}
