import SwiftUI
import VLCUI

struct VLCPlayerControls: View {
    let playbackState: PlaybackStateManager
    let proxy: VLCVideoPlayer.Proxy
    
    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 30) {
                Button {
                    proxy.jumpBackward(10)
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 25))
                        .padding(5)
                }
                .buttonStyle(.glass)
                
                Button {
                    if playbackState.isPlaying {
                        proxy.pause()
                    } else {
                        proxy.play()
                    }
                } label: {
                    Image(systemName: playbackState.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 45))
                        .padding(10)
                }
                .buttonStyle(.glass)
                
                Button {
                    proxy.jumpForward(10)
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 25))
                        .padding(5)
                }
                .buttonStyle(.glass)
            }
            .buttonBorderShape(.circle)
        }
    }
}
