import SwiftUI
import VLCUI

struct VLCPlayerKeyboardShortcuts: ViewModifier {
    let playbackState: PlaybackStateManager
    let proxy: VLCVideoPlayer.Proxy
    
    func body(content: Content) -> some View {
        content
            .onKeyPress(.space) {
                playbackState.isPlaying.toggle()
                if playbackState.isPlaying {
                    proxy.play()
                } else {
                    proxy.pause()
                }
                return .handled
            }
            .onKeyPress(.leftArrow) {
                proxy.jumpBackward(.seconds(10))
                return .handled
            }
            .onKeyPress(.rightArrow) {
                proxy.jumpForward(.seconds(10))
                return .handled
            }
            .onKeyPress(.upArrow) {
                // Volume up
                return .handled
            }
            .onKeyPress(.downArrow) {
                // Volume down
                return .handled
            }
    }
}

extension View {
    func mediaPlayerKeyboardShortcuts(
        playbackState: PlaybackStateManager,
        proxy: VLCVideoPlayer.Proxy,
    ) -> some View {
        self.modifier(VLCPlayerKeyboardShortcuts(
            playbackState: playbackState,
            proxy: proxy
        ))
    }
}
