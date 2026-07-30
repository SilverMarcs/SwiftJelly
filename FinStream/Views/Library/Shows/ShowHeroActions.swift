import SwiftUI
import JellyfinAPI

struct ShowHeroActions: View {
    @Binding private var show: BaseItemDto
    let vm: ShowDetailViewModel

    /// When provided, the hero's focus scope uses this namespace so a parent can
    /// bias default focus onto the Play button.
    private let externalFocusNamespace: Namespace.ID?

    /// When provided, lets a parent programmatically move focus onto the Play
    /// button (e.g. when the hero scrolls back into view).
    private let playFocus: FocusState<Bool>.Binding?

    init(show: Binding<BaseItemDto>, externalFocusNamespace: Namespace.ID? = nil, playFocus: FocusState<Bool>.Binding? = nil) {
        self._show = show
        self.vm = ShowDetailViewModel(item: show.wrappedValue)
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
            favoriteItem: vm.show,
            externalFocusNamespace: externalFocusNamespace,
            playFocus: playFocus
        ) {
            ShowPlayButton(vm: vm)
        }
        .environment(\.refresh, refreshAllAndSync)
    }

    private func refreshAllAndSync() async {
        await vm.refreshAll()
        show = vm.show
    }
}
