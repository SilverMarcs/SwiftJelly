import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerView: View {
    @Environment(\.refresh) var refresh
    let item: BaseItemDto
    
    @State var stateManager: AVPlayerStateManager?
    
    let startTimeSeconds: Int
    
    init(item: BaseItemDto) {
        self.item = item
        self.startTimeSeconds = JFAPI.getStartTimeSeconds(for: item)
        
        if AVPlayerSupportChecker.isSupported(item: item) {
            self._stateManager = State(initialValue: AVPlayerStateManager(item: item))
        }
    }

    var body: some View {
        Group {
            if let stateManager = stateManager {
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
                                mediaPlayerWindow.title = item.derivedNavigationTitle
                            }
                        }
                    }
                #else
                AVPlayerIos(startTimeSeconds: startTimeSeconds, stateManager: stateManager)
                    .ignoresSafeArea()

                #endif
            } else {
                Text("Playing MKV is currently not supported")
            }
        }
        .onDisappear {
            cleanup()
        }
    }
    
    func cleanup() {
        stateManager?.stop()
        if let handler = RefreshHandlerContainer.shared.refresh {
            Task { await handler() }
        }
    }
}
