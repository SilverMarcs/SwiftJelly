import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerView: View {
    let item: BaseItemDto
    @State private var player: AVPlayer
    @StateObject private var stateManager: AVPlayerStateManager
    
    let startTimeSeconds: Int
    
    init(item: BaseItemDto) {
        self.item = item
        self.startTimeSeconds = JFAPI.shared.getStartTimeSeconds(for: item)
        let playbackURL = try? JFAPI.shared.getPlaybackURL(for: item)
        
        self._stateManager = StateObject(wrappedValue: AVPlayerStateManager(item: item))
        self._player = State(initialValue: AVPlayer(url: playbackURL!))
    }
    
    var body: some View {
        #if os(macOS)
        AVPlayerMac(player: player, startTimeSeconds: startTimeSeconds, stateManager: stateManager)
            .onDisappear {
                stateManager.stopPlayback()
            }
        #else
        AVPlayerIos(player: player, startTimeSeconds: startTimeSeconds, stateManager: stateManager)
            .ignoresSafeArea()
            .onDisappear {
                stateManager.stopPlayback()
            }
        #endif
    }
}
