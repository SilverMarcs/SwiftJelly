import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerViewIOS: View {
    @State private var playbackManager = PlaybackManager.shared

    var body: some View {
        Group {
            if let model = playbackManager.viewModel, let error = model.errorDescription {
                PlaybackFailureView(message: error) { Task { await model.load() } }
            } else if let model = playbackManager.viewModel, let player = model.player {
                AVPlayerIos(player: player, host: model.playerHost)
                    .allowsTightening(!model.isAutoLoadingNext)
                    .overlay {
                        MediaPlayerOverlayControls(model: model)
                    }
            } else if let model = playbackManager.viewModel, model.isLoading {
                ProgressView()
                    .tint(.white)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black, ignoresSafeAreaEdges: .all)
                    .task(id: model.item.id) {
                        await model.load()
                    }
            }
        }
        .onDisappear { playbackManager.playerDidDisappear() }
    }
}
