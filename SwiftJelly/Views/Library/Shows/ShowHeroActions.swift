import SwiftUI
import JellyfinAPI

struct ShowHeroActions: View {
    @Binding private var show: BaseItemDto
    let vm: ShowDetailViewModel

    @Namespace private var actionButtonsNamespace

    init(show: Binding<BaseItemDto>) {
        self._show = show
        self.vm = ShowDetailViewModel(item: show.wrappedValue)
    }

    var body: some View {
        HStack(spacing: spacing) {
            ShowPlayButton(vm: vm)
                .prefersDefaultFocus(in: actionButtonsNamespace)

            #if os(tvOS)
            HeroInfoButton(item: show)
            #endif

            MarkPlayedButton(item: vm.selectedSeason)
                .adaptiveDisabled(vm.playButtonDisabled)

            FavoriteButton(item: vm.show)
        }
        .focusScope(actionButtonsNamespace)
        .environment(\.refresh, refreshAllAndSync)
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
    
    private func refreshAllAndSync() async {
        await vm.refreshAll()
        show = vm.show
    }
}
