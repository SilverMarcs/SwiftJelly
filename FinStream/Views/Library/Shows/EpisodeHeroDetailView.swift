import SwiftUI
import JellyfinAPI

struct EpisodeHeroDetailView: View {
    let vm: EpisodeDetailViewModel

    var body: some View {
        HeroBackdropView(
            item: vm.episode,
            logoItem: vm.show,
            genreItem: (vm.episode.genres?.isEmpty ?? true) ? vm.show : vm.episode,
            badge: vm.episode.seasonEpisodeString
        ) {
            HeroActionButtons(
                context: .detail,
                usesGlassContainer: true,
                infoItem: nil,
                markPlayedItem: vm.episode,
                favoriteItem: nil
            ) {
                EpisodePlayButton(item: vm.episode)
            }
            .environment(\.refresh, vm.refresh)
        }
    }
}
