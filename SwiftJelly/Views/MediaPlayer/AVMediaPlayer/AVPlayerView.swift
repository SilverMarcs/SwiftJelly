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
            .task {
                if let mediaPlayerWindow = NSApplication.shared.windows.first(where: { $0.title == "Media Player" }) {
                    mediaPlayerWindow.standardWindowButton(.zoomButton)?.isEnabled = false
                    await MainActor.run {
                        mediaPlayerWindow.title = mediaItem.name ?? "Media Player"
                    }
                }
            }
            .onDisappear {
                cleanup()
            }
            .onAppear {
                RefreshHandlerContainer.shared.refresh = localMediaManager.loadRecentFiles
            }
        #else
        AVPlayerIos(startTimeSeconds: startTimeSeconds, stateManager: stateManager)
            .ignoresSafeArea()
            .onDisappear {
                cleanup()
            }
            .onAppear {
                RefreshHandlerContainer.shared.refresh = localMediaManager.loadRecentFiles
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
