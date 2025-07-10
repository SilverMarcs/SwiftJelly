import SwiftUI
import JellyfinAPI

struct UniversalMediaPlayerView: View {
    let item: BaseItemDto
    let playbackURL: URL?
    let startTimeSeconds: Int
    
    init(item: BaseItemDto) {
        self.item = item
        self.playbackURL = try? JFAPI.shared.getPlaybackURL(for: item)
        self.startTimeSeconds = JFAPI.shared.getStartTimeSeconds(for: item)
    }
    
    var body: some View {
        if let url = playbackURL {
            if AVPlayerSupportChecker.isSupported(item: item, url: url) {
                AVMediaPlayerView(item: item, startTimeSeconds: startTimeSeconds)
            } else {
                MediaPlayerView(item: item)
            }
        } else {
            Text("Unable to play this item.")
                .padding()
        }
    }
}
