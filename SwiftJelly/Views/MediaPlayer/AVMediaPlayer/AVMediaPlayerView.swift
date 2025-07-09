import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerView: View {
    let url: URL
    let startTimeSeconds: Int
    @State private var player: AVPlayer
    
    init(url: URL, startTimeSeconds: Int) {
        self.url = url
        self.startTimeSeconds = startTimeSeconds
        self._player = State(initialValue: AVPlayer(url: url))
    }
    
    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                let time = CMTime(seconds: Double(startTimeSeconds), preferredTimescale: 1)
                player.seek(to: time)
                player.play()
            }
            .onDisappear {
                player.pause()
            }
            .background(.black)
            .ignoresSafeArea(edges: .vertical)
    }
}
