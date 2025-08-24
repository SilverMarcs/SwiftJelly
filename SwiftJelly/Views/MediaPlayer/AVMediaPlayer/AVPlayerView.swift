import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerView: View {
    let mediaItem: MediaItem
    
    @State var stateManager: AVPlayerStateManager
    @Environment(LocalMediaManager.self) var localMediaManager
    
    let startTimeSeconds: Int
    
    init(mediaItem: MediaItem) {
        self.mediaItem = mediaItem
        self.startTimeSeconds = mediaItem.startTimeSeconds
        self._stateManager = State(initialValue: AVPlayerStateManager(mediaItem: mediaItem))
    }

    var body: some View {
        #if os(macOS)
        AVPlayerMac(startTimeSeconds: startTimeSeconds, stateManager: stateManager)
            .ignoresSafeArea()
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
            .aspectRatio(16/9, contentMode: .fit)
            .gesture(WindowDragGesture())
            .navigationTitle(mediaItem.name ?? "Media Player")
            .onDisappear {
                cleanup()
            }
        #else
        AVPlayerIos(startTimeSeconds: startTimeSeconds, stateManager: stateManager)
            .ignoresSafeArea()
            .onDisappear {
                cleanup()
            }
        #endif
    }
    
    func cleanup() {
        stateManager.close()
        if let handler = RefreshHandlerContainer.shared.refresh {
            Task { await handler() }
        }
    }
}
