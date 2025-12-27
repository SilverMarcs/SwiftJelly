import SwiftUI
import JellyfinAPI

struct ShowHeroDetailView: View {
    let vm: ShowDetailViewModel

    var body: some View {
        HeroBackdropView(item: vm.show) {
            HStack(spacing: spacing) {
                ShowPlayButton(vm: vm)

                if let season = vm.selectedSeason {
                    MarkPlayedButton(item: season)
                }

                FavoriteButton(item: vm.show)
            }
            .environment(\.refresh, vm.refreshAll)
        }
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        15
        #elseif os(macOS)
        8
        #else
        4
        #endif
    }
}
