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

    
    var body: some View {
        #if os(macOS)
        AVPlayerMac(player: player, startTimeSeconds: startTimeSeconds, stateManager: stateManager)
            .ignoresSafeArea()
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
            .aspectRatio(16/9, contentMode: .fit)
            .gesture(WindowDragGesture())
            .task {
                 if let mediaPlayerWindow = NSApplication.shared.windows.first(where: { $0.title == "Media Player" }) {
                     mediaPlayerWindow.standardWindowButton(.zoomButton)?.isEnabled = false
                     await MainActor.run {
                         mediaPlayerWindow.title = item.derivedNavigationTitle
                     }
                 }
             }
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
