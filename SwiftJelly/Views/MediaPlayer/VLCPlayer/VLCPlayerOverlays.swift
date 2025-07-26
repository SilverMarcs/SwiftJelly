import SwiftUI
import JellyfinAPI
import VLCUI

struct VLCPlayerOverlays: ViewModifier {
    @Environment(\.dismiss) var dismiss

    let item: BaseItemDto
    let proxy: VLCVideoPlayer.Proxy
    let playbackState: PlaybackStateManager
    let playbackInfo: VLCVideoPlayer.PlaybackInformation?
    let subtitleManager: SubtitleManager
    
    @State private var controlsVisible: Bool = false
    @State private var isAspectFillMode = false
    
    func body(content: Content) -> some View {
        content
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
                            playbackInfo: playbackInfo,
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
#if !os(macOS)
            .ignoresSafeArea(edges: isAspectFillMode ? .horizontal : [])
            .overlay(alignment: .top) {
                if controlsVisible {
                    HStack {
                        Button {
                            isAspectFillMode.toggle()
                            if isAspectFillMode {
                                proxy.aspectFill(1.0)
                            } else {
                                proxy.aspectFill(0.0)
                            }
                        } label: {
                            Image(systemName: isAspectFillMode ? "rectangle.arrowtriangle.2.inward" : "rectangle.arrowtriangle.2.outward")
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        
                        Spacer()
                        
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .padding(2)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                    }
                }
            }
#endif
    }
}

extension View {
    func mediaPlayerOverlays(
        item: BaseItemDto,
        proxy: VLCVideoPlayer.Proxy,
        playbackState: PlaybackStateManager,
        playbackInfo: VLCVideoPlayer.PlaybackInformation?,
        subtitleManager: SubtitleManager,
    ) -> some View {
        self.modifier(VLCPlayerOverlays(
            item: item,
            proxy: proxy,
            playbackState: playbackState,
            playbackInfo: playbackInfo,
            subtitleManager: subtitleManager,
        ))
    }
}
