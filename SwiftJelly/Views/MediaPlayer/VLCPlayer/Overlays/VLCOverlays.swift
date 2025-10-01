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
    #if os(iOS)
    @State private var suppressSingleTapToggleUntil: Date? = nil
    #endif
    
    func body(content: Content) -> some View {
        content
            .ignoresSafeArea()
            #if !os(macOS)
            .overlay(alignment: .center) {
                // Gesture layer lives underneath visual controls; it's always active
                VLCGestureLayer(proxy: proxy) {
                    // If a double-tap happened, suppress single-tap toggle briefly
                    suppressSingleTapToggleUntil = Date().addingTimeInterval(1)
                }
            }
            .overlay(alignment: .top) {
                if controlsVisible {
                    VLCPlayerTopOverlay(proxy: proxy, isAspectFillMode: $isAspectFillMode)
                        .tint(.white)
                }
            }
            .overlay(alignment: .center) {
                VLCMobileControls(
                    playbackState: playbackState,
                    proxy: proxy,
                    controlsVisible: controlsVisible,
                )
                .tint(.white)
            }
            #endif
            .simultaneousGesture(
                TapGesture(count: 1)
                    .onEnded {
                        #if os(iOS)
                        // Ignore if we just handled a double-tap
                        if let until = suppressSingleTapToggleUntil, Date() < until { return }
                        #endif
                        withAnimation(.easeInOut(duration: 0.2)) { controlsVisible.toggle() }
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
