import SwiftUI
import JellyfinAPI
import VLCUI

struct VLCPlayerOverlays: ViewModifier {
    @Environment(\.dismiss) var dismiss

    let proxy: VLCVideoPlayer.Proxy
    let playbackState: PlaybackStateManager
    let subtitleManager: SubtitleManager
    
    @State private var controlsVisible: Bool = true
    @State private var isAspectFillMode = false
    
    func body(content: Content) -> some View {
        content
            #if !os(macOS)
            .overlay(alignment: .top) {
                if controlsVisible {
                    VLCPlayerTopOverlay(proxy: proxy, isAspectFillMode: $isAspectFillMode)
                        .padding(.top, 5)
                        .tint(.white)
                }
            }
            .overlay(alignment: .center) {
                if controlsVisible {
                    VLCMobileControls(
                        playbackState: playbackState,
                        proxy: proxy,
                        controlsVisible: controlsVisible,
                    )
                    .tint(.white)
                }
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
                    #else
                        .padding(.bottom, -6)
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
