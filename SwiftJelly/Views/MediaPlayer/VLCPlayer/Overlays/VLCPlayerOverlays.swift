import SwiftUI
import JellyfinAPI
import VLCUI

struct VLCPlayerOverlays: ViewModifier {
    @Environment(\.dismiss) var dismiss

    let item: BaseItemDto
    let proxy: VLCVideoPlayer.Proxy
    let playbackState: PlaybackStateManager
    let subtitleManager: SubtitleManager
    
    @State private var controlsVisible: Bool = false
    @State private var isAspectFillMode = false
    
    func body(content: Content) -> some View {
        content
            #if !os(macOS)
            .ignoresSafeArea(edges: isAspectFillMode ? .horizontal : [])
            .overlay(alignment: .top) {
                if controlsVisible {
                    VLCPlayerTopOverlay(proxy: proxy)
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
            .overlay {
                if controlsVisible {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: controlsVisible)
                        .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .center) {
                if controlsVisible {
                    VLCPlayerControls(
                        playbackState: playbackState,
                        proxy: proxy
                    )
                }
            }
            .overlay(alignment: .bottom) {
                if controlsVisible {
                    VStack {
                        VLCPlayerInfoBar(
                            item: item,
                            proxy: proxy,
                            subtitleManager: subtitleManager
                        )
                        VLCPlayerProgressBar(
                            playbackState: playbackState,
                            proxy: proxy
                        )
                    }
                    .padding()
                }
            }
    }
}

extension View {
    func mediaPlayerOverlays(
        item: BaseItemDto,
        proxy: VLCVideoPlayer.Proxy,
        playbackState: PlaybackStateManager,
        subtitleManager: SubtitleManager,
    ) -> some View {
        self.modifier(VLCPlayerOverlays(
            item: item,
            proxy: proxy,
            playbackState: playbackState,
            subtitleManager: subtitleManager,
        ))
    }
}
