import SwiftUI
import JellyfinAPI

struct MovieHeroDetailView: View {
    let vm: MovieDetailViewModel

    var body: some View {
        HeroBackdropView(item: vm.movie) {
            HStack(spacing: spacing) {
                MoviePlayButton(item: vm.movie)

                MarkPlayedButton(item: vm.movie)

                FavoriteButton(item: vm.movie)
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
        0
        #endif
    }
}
