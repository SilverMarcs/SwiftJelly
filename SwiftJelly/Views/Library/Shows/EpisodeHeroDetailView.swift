import SwiftUI
import JellyfinAPI

struct EpisodeHeroDetailView: View {
    let vm: EpisodeDetailViewModel

    var body: some View {
        HeroBackdropView(
            item: vm.episode,
            logoItem: vm.show,
            badge: vm.episode.seasonEpisodeString
        ) {
            GlassEffectContainer(spacing: spacing) {
                HStack(spacing: spacing) {
                    EpisodePlayButton(item: vm.episode)

                    MarkPlayedButton(item: vm.episode)
                }
            }
            .environment(\.refresh, vm.refresh)
        }
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        15
        #elseif os(macOS)
        8
        #else
        6
        #endif
    }
}
