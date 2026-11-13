import SwiftUI
import JellyfinAPI

struct MovieDetailHeroView: View {
    let vm: MovieDetailViewModel

    var body: some View {
        HeroBackdropView(item: vm.movie) {
            HeroActionButtons(
                context: .detail,
                usesGlassContainer: false,
                infoItem: nil,
                markPlayedItem: vm.movie,
                favoriteItem: vm.movie
            ) {
                MoviePlayButton(item: vm.movie)
            }
            .environment(\.refresh, vm.refresh)
        }
    }
}
