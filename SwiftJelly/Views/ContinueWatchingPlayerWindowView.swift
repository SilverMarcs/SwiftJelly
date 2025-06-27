import SwiftUI
import VLCUI

struct ContinueWatchingPlayerWindowView: View {
    let item: MediaItem
    let server: Server
    let user: User

    var body: some View {
        if let url = item.playbackURL(for: server, user: user) {
            VLCVideoPlayer(
                configuration: .init(
                    url: url,
                    autoPlay: true,
                    startSeconds: .seconds(Int64(item.startTimeSeconds))
                )
            )
        } else {
            Text("Unable to play this item.")
                .padding()
        }
    }
}
