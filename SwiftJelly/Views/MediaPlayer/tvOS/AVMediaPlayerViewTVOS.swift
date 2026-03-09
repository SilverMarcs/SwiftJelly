import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerViewTVOS: View {
    @State private var playbackManager = PlaybackManager.shared

    var body: some View {
        if let model = playbackManager.viewModel, let player = model.player {
            AVPlayerTvOS(
                player: player,
                item: model.item,
                isTransitioning: model.isAutoLoadingNext,
                showSkipIntro: model.shouldShowSkipIntro,
                nextEpisode: model.nextEpisode,
                creditsStartSeconds: model.creditsStartSeconds,
                onSkipIntro: { Task { await model.skipIntro() } },
                onNextEpisode: { Task { await model.transitionToNextEpisode() } },
                onDismiss: {
                    playbackManager.endPlayback()
                }
            )
            // TODO: fix this; setting an ID here will cause the video player to flicker, when a new episode is loaded.
            // .id("\(model.item.id ?? "")_\(model.nextEpisode?.id ?? "none")")
                .allowsTightening(!model.isAutoLoadingNext)
                .task(id: player.timeControlStatus) {
                    await PlaybackUtilities.reportPlaybackProgress(
                        player: player,
                        item: model.item,
                        isPaused: true
                    )
                }
                .onDisappear {
                    PlaybackManager.shared.endPlayback()
                }
        } else if let model = playbackManager.viewModel, model.isLoading {
            ProgressView()
                .tint(.white)
                .controlSize(.extraLarge)
                .scaleEffect(1.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black, ignoresSafeAreaEdges: .all)
                .task(id: model.playbackToken) {
                    await model.load()
                }
        }
    }
}
