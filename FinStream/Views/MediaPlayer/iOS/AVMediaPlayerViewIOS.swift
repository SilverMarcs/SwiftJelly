import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerViewIOS: View {
    @State private var playbackManager = PlaybackManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if let model = playbackManager.viewModel, let error = model.errorDescription {
                PlaybackFailureView(message: error) { Task { await model.load() } }
            } else if let model = playbackManager.viewModel, let player = model.player {
                AVPlayerIos(player: player)
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
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { playbackManager.viewModel?.didEnterBackground() }
            else if phase == .active { playbackManager.viewModel?.didBecomeActive() }
        }
        .onDisappear { playbackManager.endPlayback() }
    }
}
