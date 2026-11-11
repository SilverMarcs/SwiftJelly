import SwiftUI
import JellyfinAPI

struct ShowHeroActions: View {
    @Binding private var show: BaseItemDto
    /// Owned by the view so the loaded next episode survives the carousel recreating it.
    @State private var vm: ShowDetailViewModel
    private let externalFocusNamespace: Namespace.ID?
    private let playFocus: FocusState<Bool>.Binding?

    init(show: Binding<BaseItemDto>, externalFocusNamespace: Namespace.ID? = nil, playFocus: FocusState<Bool>.Binding? = nil) {
        self._show = show
        self._vm = State(initialValue: ShowDetailViewModel(item: show.wrappedValue))
        self.externalFocusNamespace = externalFocusNamespace
        self.playFocus = playFocus
    }

    var body: some View {
        HeroActionButtons(
            context: .carousel,
            usesGlassContainer: true,
            infoItem: show,
            markPlayedItem: vm.selectedSeason,
            markPlayedDisabled: vm.playButtonDisabled,
            markAllEpisodesWatched: vm.markSelectedSeasonWatched,
            canMarkAllEpisodesWatched: vm.canMarkSelectedSeasonWatched,
            favoriteItem: vm.show,
            externalFocusNamespace: externalFocusNamespace,
            playFocus: playFocus
        ) {
            ShowPlayButton(vm: vm)
        }
        .environment(\.refresh, refreshAllAndSync)
        .task(id: show.id) {
            await vm.loadQuickNextEpisode()
        }
    }

    private func refreshAllAndSync() async {
        await vm.refreshAll()
        show = vm.show
    }
}
