import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerViewIOS: View {
    @State private var model: MediaPlaybackViewModel
    
    init(item: BaseItemDto) {
        _model = State(initialValue: MediaPlaybackViewModel(item: item))
    }

    var body: some View {
        if let player = model.player {
            AVPlayerIos(player: player)
            .allowsTightening(!model.isAutoLoadingNext)
            .overlay {
                MediaPlayerOverlayControls(model: model)
            }
            .task(id: player.timeControlStatus) {
                await PlaybackUtilities.reportPlaybackProgress(
                    player: player,
                    item: model.item,
//                    isPaused: player.timeControlStatus != .playing
                    isPaused: true
                )
            }
            .onDisappear {
                Task { await model.cleanup() }
            }
        } else if model.isLoading {
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black, ignoresSafeAreaEdges: .all)
                .task(id: model.playbackToken) {
                    await model.load()
                }
        }
    }
}
