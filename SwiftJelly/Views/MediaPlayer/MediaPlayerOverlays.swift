import SwiftUI
import JellyfinAPI
import VLCUI

struct MediaPlayerOverlays: ViewModifier {
    @Environment(\.dismiss) var dismiss
    @Binding var controlsVisible: Bool
    let item: BaseItemDto
    let proxy: VLCVideoPlayer.Proxy
    let playbackState: PlaybackStateManager
    let playbackInfo: VLCVideoPlayer.PlaybackInformation?
    let subtitleManager: SubtitleManager

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
                    MediaPlayerControls(
                        playbackState: playbackState,
                        proxy: proxy
                    )
                }
            }
            .overlay(alignment: .bottom) {
                if controlsVisible {
                    VStack {
                        MediaPlayerInfoBar(
                            item: item,
                            proxy: proxy,
                            playbackInfo: playbackInfo,
                            subtitleManager: subtitleManager
                        )
                        MediaPlayerProgressBar(
                            playbackState: playbackState,
                            proxy: proxy
                        )
                    }
                    .padding()
                }
            }
#if !os(macOS)
            .overlay(alignment: .topTrailing) {
                if controlsVisible {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
//                    .buttonStyle(.plain)
                    .padding()
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
    ) -> some View {
        self.modifier(MediaPlayerOverlays(
            controlsVisible: controlsVisible,
            item: item,
            proxy: proxy,
            playbackState: playbackState,
            playbackInfo: playbackInfo,
            subtitleManager: subtitleManager,
        ))
    }
}
