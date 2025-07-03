import Foundation
import JellyfinAPI
import VLCUI
import Combine

@MainActor
class SubtitleManager: ObservableObject {
    @Published var availableSubtitles: [UnifiedSubtitle] = []
    @Published var selectedSubtitle: UnifiedSubtitle?
    @Published var isLoading = false
    
    private let item: BaseItemDto
    private var vlcProxy: VLCVideoPlayer.Proxy?
    private var externalSubtitleChildren: [VLCVideoPlayer.PlaybackChild] = []
    
    init(item: BaseItemDto) {
        self.item = item
    }
    
    func setVLCProxy(_ proxy: VLCVideoPlayer.Proxy) {
        self.vlcProxy = proxy
    }
    
    /// Load both embedded and external subtitles
    func loadSubtitles(embeddedTracks: [MediaTrack]) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let combinedSubtitles = try await JFAPI.shared.getCombinedSubtitles(
                for: item,
                embeddedTracks: embeddedTracks
            )
            
            availableSubtitles = combinedSubtitles
            
//            print("Available subtitles: \(availableSubtitles.count)")
            
            // Create playback children for external subtitles
            externalSubtitleChildren = try JFAPI.shared.createSubtitlePlaybackChildren(
                from: combinedSubtitles.filter { $0.isExternal }
            )
            
            // Set default selection (first available or none)
            if selectedSubtitle == nil {
                selectedSubtitle = availableSubtitles.first ?? UnifiedSubtitle.none
            }
            
        } catch {
            print("Failed to load external subtitles: \(error)")
            // Fallback to just embedded subtitles
            availableSubtitles = embeddedTracks.map { UnifiedSubtitle(from: $0) }
        }
    }
    
    /// Load only external subtitles before VLC initialization
    func loadExternalSubtitles() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let allStreams = try await JFAPI.shared.getAllSubtitleStreams(for: item)
            let externalSubtitles = allStreams.filter { $0.deliveryURL != nil }.map { UnifiedSubtitle(from: $0) }
            
            // Create playback children for external subtitles
            externalSubtitleChildren = try JFAPI.shared.createSubtitlePlaybackChildren(from: externalSubtitles)
            
            print("Loaded \(externalSubtitles.count) external subtitles, \(externalSubtitleChildren.count) playback children")
            
        } catch {
            print("Failed to load external subtitles: \(error)")
            externalSubtitleChildren = []
        }
    }
    
    /// Load embedded subtitles and combine with already loaded external ones
    func loadEmbeddedSubtitles(embeddedTracks: [MediaTrack]) async {
        // Convert embedded tracks to UnifiedSubtitle
        let embeddedSubtitles = embeddedTracks.map { UnifiedSubtitle(from: $0) }
        
        // Get external subtitles that were already loaded
        let externalSubtitles = try? await JFAPI.shared.getAllSubtitleStreams(for: item).map { UnifiedSubtitle(from: $0) }.filter { $0.isExternal }
        
        // Combine both
        var combinedSubtitles = embeddedSubtitles
        if let external = externalSubtitles {
            combinedSubtitles.append(contentsOf: external)
        }
        
        availableSubtitles = combinedSubtitles
        
        // Set default selection if none selected
        if selectedSubtitle == nil {
            selectedSubtitle = availableSubtitles.first ?? UnifiedSubtitle.none
        }
    }
    
    /// Select a subtitle track
    func selectSubtitle(_ subtitle: UnifiedSubtitle) {
        selectedSubtitle = subtitle
        
        guard let proxy = vlcProxy else { return }
        
        if subtitle.index == -1 {
            // Disable subtitles
            proxy.setSubtitleTrack(.absolute(-1))
        } else if subtitle.isExternal {
            // For external subtitles, we need to use a different approach
            // External subtitles should be loaded as PlaybackChildren and referenced by their order
            let externalSubtitles = availableSubtitles.filter { $0.isExternal }
            if let externalIndex = externalSubtitles.firstIndex(where: { $0.id == subtitle.id }) {
                // External subtitles come after embedded ones in VLC's track numbering
                let embeddedCount = availableSubtitles.filter { !$0.isExternal }.count
                proxy.setSubtitleTrack(.absolute(embeddedCount + externalIndex))
            }
        } else {
            // For embedded subtitles
            proxy.setSubtitleTrack(.absolute(subtitle.index))
        }
    }
    
    /// Get PlaybackChildren for VLC configuration
    func getPlaybackChildren() -> [VLCVideoPlayer.PlaybackChild] {
        return externalSubtitleChildren
    }
    
    /// Update when VLC playback info changes
    func updateFromPlaybackInfo(_ info: VLCVideoPlayer.PlaybackInformation) {
        // Update selected subtitle based on VLC's current track
//        if let currentTrack = info.currentSubtitleTrack {
            // Find matching subtitle
        if let matchingSubtitle = availableSubtitles.first(where: { $0.index == info.currentSubtitleTrack.index }) {
                selectedSubtitle = matchingSubtitle
            }
//        } else {
//            selectedSubtitle = UnifiedSubtitle.none
//        }
    }
}
