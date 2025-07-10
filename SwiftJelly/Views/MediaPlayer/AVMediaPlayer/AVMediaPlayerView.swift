import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerView: View {
    let item: BaseItemDto
    let startTimeSeconds: Int
    @State private var player: AVPlayer
    
    init(item: BaseItemDto, startTimeSeconds: Int) {
        self.item = item
        self.startTimeSeconds = startTimeSeconds
        let playbackURL = try? JFAPI.shared.getPlaybackURL(for: item)
        self._player = State(initialValue: AVPlayer(url: playbackURL!))
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
