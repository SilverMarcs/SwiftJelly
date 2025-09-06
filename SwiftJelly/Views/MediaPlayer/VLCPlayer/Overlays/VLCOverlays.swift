import SwiftUI
import JellyfinAPI
import VLCUI

struct VLCPlayerOverlays: ViewModifier {
    @Environment(\.dismiss) var dismiss

    let proxy: VLCVideoPlayer.Proxy
    let playbackState: PlaybackStateManager
    let subtitleManager: SubtitleManager
    
    @State private var controlsVisible: Bool = false
    @State private var isAspectFillMode = false
    
    func body(content: Content) -> some View {
        content
            #if !os(macOS)
            .ignoresSafeArea(edges: isAspectFillMode ? [.horizontal, .vertical] : [.vertical])
            .overlay(alignment: .top) {
                if controlsVisible {
                    VLCPlayerTopOverlay(proxy: proxy, isAspectFillMode: $isAspectFillMode)
                }
            }
            .overlay(alignment: .center) {
                VLCMobileControls(
                    playbackState: playbackState,
                    proxy: proxy,
                    controlsVisible: $controlsVisible
                )
            }
            #endif
            .simultaneousGesture(
                TapGesture(count: 1)
                    .onEnded {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            controlsVisible.toggle()
                        }
                    }
            )
            .overlay(alignment: .bottom) {
                if controlsVisible {
                    VLCControlsOverlay(playbackState: playbackState, proxy: proxy, subtitleManager: subtitleManager)
                    #if os(macOS)
                        .padding()
                    #endif
                }
            }
    }
}

extension View {
    func mediaPlayerOverlays(
        proxy: VLCVideoPlayer.Proxy,
        playbackState: PlaybackStateManager,
        subtitleManager: SubtitleManager,
    ) -> some View {
        self.modifier(VLCPlayerOverlays(
            proxy: proxy,
            playbackState: playbackState,
            subtitleManager: subtitleManager,
        ))
    }
}
