import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerViewIOS: View {
    @State private var playbackManager = PlaybackManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        if let model = playbackManager.viewModel, let player = model.player {
            AVPlayerIos(player: player)
                .allowsTightening(!model.isAutoLoadingNext)
                .overlay {
                    MediaPlayerOverlayControls(model: model)
                }
                .task(id: player.timeControlStatus) {
                    if player.timeControlStatus == .playing {
                        await model.reportPlaybackStart()
                    } else {
                        await model.reportProgress()
                    }
                }
                .task(id: scenePhase) {
                    if scenePhase == .background {
                        await model.reportProgress()
                    }
                }
                .onDisappear {
                    PlaybackManager.shared.endPlayback()
                }
        } else if let model = playbackManager.viewModel, model.isLoading {
            ProgressView()
                .tint(.white)
                .controlSize(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black, ignoresSafeAreaEdges: .all)
                .task(id: model.playbackToken) {
                    await model.load()
                }
        }
    }
}
