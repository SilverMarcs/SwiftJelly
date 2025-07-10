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
        #if os(iOS)
        AVPlayerIos(player: player, startTimeSeconds: startTimeSeconds)
            .ignoresSafeArea()
        #elseif os(macOS)
        AVPlayerMac(player: player, startTimeSeconds: startTimeSeconds)
//            .ignoresSafeArea()
        #endif
    }
}
