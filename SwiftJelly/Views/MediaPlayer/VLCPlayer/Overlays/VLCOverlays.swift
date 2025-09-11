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
    @State private var hideTimer: Timer?
    
    func body(content: Content) -> some View {
        content
            #if !os(macOS)
            .ignoresSafeArea(edges: isAspectFillMode ? [.horizontal, .vertical] : [.vertical])
            .overlay(alignment: .top) {
                if controlsVisible {
                    VLCPlayerTopOverlay(proxy: proxy, isAspectFillMode: $isAspectFillMode)
                        .simultaneousGesture(
                            TapGesture()
                                .onEnded {
                                    resetHideTimer()
                                }
                        )
                }
            }
            .overlay(alignment: .center) {
                VLCMobileControls(
                    playbackState: playbackState,
                    proxy: proxy,
                    controlsVisible: $controlsVisible
                )
                .simultaneousGesture(
                    TapGesture()
                        .onEnded {
                            resetHideTimer()
                        }
                )
            }
            #endif
            .simultaneousGesture(
                TapGesture(count: 1)
                    .onEnded {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            controlsVisible.toggle()
                        }
                        resetHideTimer()
                    }
            )
            .overlay(alignment: .bottom) {
                if controlsVisible {
                    VLCControlsOverlay(playbackState: playbackState, proxy: proxy, subtitleManager: subtitleManager)
                        .simultaneousGesture(
                            TapGesture()
                                .onEnded {
                                    resetHideTimer()
                                }
                        )
                    #if os(macOS)
                        .padding()
                    #endif
                }
            }
            .onChange(of: controlsVisible) { oldValue, newValue in
                if newValue {
                    startHideTimer()
                } else {
                    hideTimer?.invalidate()
                    hideTimer = nil
                }
            }
    }
    
    private func startHideTimer() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                controlsVisible = false
            }
        }
    }
    
    private func resetHideTimer() {
        if controlsVisible {
            startHideTimer()
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
