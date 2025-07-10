import SwiftUI
import VLCUI

struct VLCPlayerKeyboardShortcuts: ViewModifier {
    let playbackState: PlaybackStateManager
    let proxy: VLCVideoPlayer.Proxy
    
    func body(content: Content) -> some View {
        content
            .onKeyPress(.space) {
                if playbackState.isPlaying {
                    proxy.pause()
                } else {
                    proxy.play()
                }
                return .handled
            }
            .onKeyPress(.leftArrow) {
                proxy.jumpBackward(10)
                return .handled
            }
            .onKeyPress(.rightArrow) {
                proxy.jumpForward(10)
                return .handled
            }
    }
}

extension View {
    func mediaPlayerKeyboardShortcuts(
        playbackState: PlaybackStateManager,
        proxy: VLCVideoPlayer.Proxy
    ) -> some View {
        modifier(VLCPlayerKeyboardShortcuts(
            playbackState: playbackState,
            proxy: proxy
        ))
    }
}
