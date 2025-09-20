import SwiftUI
import JellyfinAPI
import VLCUI

struct VLCPlayerOverlays: ViewModifier {
    @Environment(\.dismiss) var dismiss

    let proxy: VLCVideoPlayer.Proxy
    let playbackState: PlaybackStateManager
    let subtitleManager: SubtitleManager
    
    @State private var isAspectFillMode = false
    
    func body(content: Content) -> some View {
        content
            #if !os(macOS)
            .ignoresSafeArea(edges: isAspectFillMode ? [.horizontal, .vertical] : [.vertical])
            .overlay(alignment: .top) {
                VLCPlayerTopOverlay(proxy: proxy, isAspectFillMode: $isAspectFillMode)
                    .padding(.top, -10)
            }
            .overlay(alignment: .center) {
                VLCMobileControls(
                    playbackState: playbackState,
                    proxy: proxy
                )
            }
            #endif
            .overlay(alignment: .bottom) {
                VLCControlsOverlay(playbackState: playbackState, proxy: proxy, subtitleManager: subtitleManager)
                #if os(macOS)
                    .padding()
                #else
                    .padding(.bottom, -10)
                #endif
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
