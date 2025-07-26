import SwiftUI
import JellyfinAPI
import VLCUI

struct VLCPlayerOverlays: ViewModifier {
    @Environment(\.dismiss) var dismiss
    @Binding var controlsVisible: Bool
    let item: BaseItemDto
    let proxy: VLCVideoPlayer.Proxy
    let playbackState: PlaybackStateManager
    let playbackInfo: VLCVideoPlayer.PlaybackInformation?
    let subtitleManager: SubtitleManager
    @Binding var isAspectFillMode: Bool
    let onToggleAspectFill: () -> Void
    
    func body(content: Content) -> some View {
        content
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
            .overlay(alignment: .top) {
                if controlsVisible {
                    HStack {
                        Button {
                            onToggleAspectFill()
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
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                    }
//                    .padding()
                }
            }
#endif
    }
}

extension View {
    func mediaPlayerOverlays(
        controlsVisible: Binding<Bool>,
        item: BaseItemDto,
        proxy: VLCVideoPlayer.Proxy,
        playbackState: PlaybackStateManager,
        playbackInfo: VLCVideoPlayer.PlaybackInformation?,
        subtitleManager: SubtitleManager,
        isAspectFillMode: Binding<Bool>,
        onToggleAspectFill: @escaping () -> Void
    ) -> some View {
        self.modifier(VLCPlayerOverlays(
            controlsVisible: controlsVisible,
            item: item,
            proxy: proxy,
            playbackState: playbackState,
            playbackInfo: playbackInfo,
            subtitleManager: subtitleManager,
            isAspectFillMode: isAspectFillMode,
            onToggleAspectFill: onToggleAspectFill
        ))
    }
}
