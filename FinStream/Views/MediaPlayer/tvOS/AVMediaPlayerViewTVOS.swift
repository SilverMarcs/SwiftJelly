import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerViewTVOS: View {
    @State private var playbackManager = PlaybackManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if let model = playbackManager.viewModel, let error = model.errorDescription {
                PlaybackFailureView(message: error) { Task { await model.load() } }
            } else if let model = playbackManager.viewModel, let player = model.player {
                AVPlayerTvOS(
                    player: player,
                    item: model.item,
                    isTransitioning: model.isAutoLoadingNext,
                    showSkipIntro: model.shouldShowSkipIntro,
                    nextEpisode: model.nextEpisode,
                    creditsStartSeconds: model.creditsStartSeconds,
                    onSkipIntro: { Task { await model.skipIntro() } },
                    onSelectEpisode: { episode in
                        Task { await model.transition(to: episode) }
                    },
                    onNextEpisode: { Task { await model.transitionToNextEpisode() } },
                    onDismiss: {
                        playbackManager.endPlayback()
                    }
                )
                // TODO: fix this; setting an ID here will cause the video player to flicker, when a new episode is loaded.
                // .id("\(model.item.id ?? "")_\(model.nextEpisode?.id ?? "none")")
                    .allowsTightening(!model.isAutoLoadingNext)
                    .task(id: scenePhase) {
                        if scenePhase == .background {
                            await model.reportProgress()
                        }
                    }
            } else if let model = playbackManager.viewModel, model.isLoading {
                ProgressView()
                    .tint(.white)
                    .controlSize(.extraLarge)
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black, ignoresSafeAreaEdges: .all)
                    .task(id: model.item.id) {
                        await model.load()
                    }
            }
        }
        .onDisappear { playbackManager.endPlayback() }
    }
}
