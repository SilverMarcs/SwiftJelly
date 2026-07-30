import SwiftUI
import JellyfinAPI

struct ShowDetailHeroView: View {
    let vm: ShowDetailViewModel

    var body: some View {
        HeroBackdropView(item: vm.show) {
            HeroActionButtons(
                context: .detail,
                usesGlassContainer: false,
                infoItem: nil,
                markPlayedItem: vm.selectedSeason,
                markPlayedDisabled: vm.playButtonDisabled,
                favoriteItem: vm.show
            ) {
                ShowPlayButton(vm: vm)
            }
            .environment(\.refresh, vm.refreshAll)
        }
    }
}
