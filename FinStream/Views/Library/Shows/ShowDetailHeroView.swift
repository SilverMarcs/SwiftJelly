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
                markAllEpisodesWatched: vm.markSelectedSeasonWatched,
                canMarkAllEpisodesWatched: vm.canMarkSelectedSeasonWatched,
                favoriteItem: vm.show
            ) {
                ShowPlayButton(vm: vm)
            }
            .environment(\.refresh, vm.refreshAll)
        } logoAccessory: {
            SeerLibraryProcessingChip(item: vm.show)
        }
    }
}
