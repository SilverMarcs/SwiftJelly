import SwiftUI
import VLCUI

struct MediaPlayerKeyboardShortcuts: ViewModifier {
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
        modifier(MediaPlayerKeyboardShortcuts(
            playbackState: playbackState,
            proxy: proxy
        ))
    }
}
