import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerView: View {
    @Environment(\.refresh) var refresh
    let item: BaseItemDto
    
    private var player: AVPlayer?
    private var stateManager: AVPlayerStateManager?
    
    let startTimeSeconds: Int
    
    init(item: BaseItemDto) {
        self.item = item
        self.startTimeSeconds = JFAPI.shared.getStartTimeSeconds(for: item)
        
        // Move support checking here
        if AVPlayerSupportChecker.isSupported(item: item) {
            if let playbackURL = try? JFAPI.shared.getPlaybackURL(for: item) {
                self.stateManager = AVPlayerStateManager(item: item)
                self.player = AVPlayer(url: playbackURL)
            }
        }
    }

    var body: some View {
        if let player = player, stateManager != nil {
            #if os(macOS)
            AVPlayerMac(player: player, startTimeSeconds: startTimeSeconds, stateManager: stateManager!)
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
                    cleanup()
                }
            #else
            AVPlayerIos(player: player, startTimeSeconds: startTimeSeconds, stateManager: stateManager!)
                .ignoresSafeArea()
                .onDisappear {
                    cleanup()
                }
            #endif
        } else {
            Text("Playing MKV is currently not supported")
        }
    }
    
    func cleanup() {
        stateManager?.stopPlayback()
        if let handler = RefreshHandlerContainer.shared.refresh {
            Task { await handler() }
        }
    }
}
