import SwiftUI
import JellyfinAPI
import VLCUI


struct MediaPlayerView: View {
    let item: BaseItemDto
    
    @State private var proxy: VLCVideoPlayer.Proxy = .init()

    var body: some View {

        if let url = playbackURL {
            ZStack {
                VLCVideoPlayer(
                    configuration: .init(
                        url: url,
                        autoPlay: true,
                        startSeconds: .seconds(Int64(startTimeSeconds)),
                    )
                )
                .proxy(proxy)
                
                HStack(spacing: 40) {
                    Button {
                        proxy.jumpBackward(5)
                    } label: {
                        Image(systemName: "gobackward.5")
                            .font(.system(size: 32))
                    }
                    .buttonStyle(.glass)

                    Button {
                       // play pause based on current state
                    } label: {
//                        Image(systemName: /*condition*/ ? "pause.fill" : "play.fill")
//                            .font(.system(size: 40))
                    }
                    .buttonStyle(.glass)

                    Button {
                        proxy.jumpForward(5)
                    } label: {
                        Image(systemName: "goforward.5")
                            .font(.system(size: 32))
                    }
                    .buttonStyle(.glass)
                }
                
            }
            .background(.black)
        } else {
            Text("Unable to play this item.")
                .padding()
        }
    }

    private var playbackURL: URL? {
        try? JFAPI.shared.getPlaybackURL(for: item)
    }

    private var startTimeSeconds: Int {
        JFAPI.shared.getStartTimeSeconds(for: item)
    }
}
