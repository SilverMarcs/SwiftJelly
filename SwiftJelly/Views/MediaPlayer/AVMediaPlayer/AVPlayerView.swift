import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerView: View {
    @Environment(\.refresh) var refresh
    let item: BaseItemDto
    @State private var player: AVPlayer
    private var stateManager: AVPlayerStateManager
    
    let startTimeSeconds: Int
    
    init(item: BaseItemDto) {
        self.item = item
        self.startTimeSeconds = JFAPI.shared.getStartTimeSeconds(for: item)
        let playbackURL = try? JFAPI.shared.getPlaybackURL(for: item)
        
        self.stateManager = AVPlayerStateManager(item: item)
        self._player = State(initialValue: AVPlayer(url: playbackURL!))
    }
    
    #if os(macOS)
    var navigationTitle: String {
        if let seriesName = item.seriesName {
            var title = seriesName
            if let season = item.parentIndexNumber, let episode = item.indexNumber {
                title += " • S\(season)E\(episode)"
            }
            return title
        } else if let movieTitle = item.name {
            return movieTitle
        } else {
            return "Now Playing"
        }
    }
    #endif
    
    var body: some View {
        #if os(macOS)
        AVPlayerMac(player: player, startTimeSeconds: startTimeSeconds, stateManager: stateManager)
            .navigationTitle(navigationTitle)
            .onDisappear {
                stateManager.stopPlayback()
                if let handler = RefreshHandlerContainer.shared.refresh {
                    Task { await handler() }
                    RefreshHandlerContainer.shared.refresh = nil
                }
            }
        #else
        AVPlayerIos(player: player, startTimeSeconds: startTimeSeconds, stateManager: stateManager)
            .ignoresSafeArea()
            .onDisappear {
                stateManager.stopPlayback()
                if let handler = RefreshHandlerContainer.shared.refresh {
                    Task { await handler() }
                }
                RefreshHandlerContainer.shared.refresh = nil
            }
        #endif
    }
}
