import SwiftUI
import JellyfinAPI

struct ShowHeroActions: View {
    @Binding private var show: BaseItemDto
    let vm: ShowDetailViewModel
    
    init(show: Binding<BaseItemDto>) {
        self._show = show
        self.vm = ShowDetailViewModel(item: show.wrappedValue)
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            ShowPlayButton(vm: vm)

            MarkPlayedButton(item: vm.selectedSeason)
                .adaptiveDisabled(vm.playButtonDisabled)

            FavoriteButton(item: vm.show)
        }
        .environment(\.refresh, refreshAllAndSync)
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
    
    private func refreshAllAndSync() async {
        await vm.refreshAll()
        show = vm.show
    }
}
