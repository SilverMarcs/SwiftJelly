import SwiftUI
import VLCUI

struct VLCPlayerKeyboardShortcuts: ViewModifier {
    let playbackState: PlaybackStateManager
    let proxy: VLCVideoPlayer.Proxy
    let uiState: PlaybackUIState
    
    func body(content: Content) -> some View {
        content
            .onKeyPress(.space) {
                uiState.isPlaying.toggle()
                if uiState.isPlaying {
                    proxy.play()
                } else {
                    proxy.pause()
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
        uiState: PlaybackUIState
    ) -> some View {
        self.modifier(VLCPlayerKeyboardShortcuts(
            playbackState: playbackState,
            proxy: proxy,
            uiState: uiState
        ))
    }
}
