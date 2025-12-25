import SwiftUI
import JellyfinAPI

struct ShowHeroActions: View {
    @Binding private var show: BaseItemDto
    @State private var vm: ShowDetailViewModel
    
    init(show: Binding<BaseItemDto>) {
        self._show = show
        _vm = State(initialValue: ShowDetailViewModel(item: show.wrappedValue))
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            ShowPlayButton(vm: vm)
            
            if let season = vm.selectedSeason {
                MarkPlayedButton(item: season)
            }
            
            FavoriteButton(item: vm.show)
        }
        .environment(\.refresh, refreshAllAndSync)
        .task {
            await vm.loadQuickNextEpisode()
        }
        .onChange(of: show.id) { _, _ in
            vm = ShowDetailViewModel(item: show)
            Task { await vm.loadQuickNextEpisode() }
        }
    }
    
    private var loadingButton: some View {
        Button {} label: {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(.primary)
                    .controlSize(.mini)
                Text("Loading…")
            }
            .font(.callout)
            .fontWeight(.semibold)
        }
        .tint(Color(.accent).secondary)
        .buttonBorderShape(.capsule)
        .controlSize(.extraLarge)
        .buttonStyle(.glassProminent)
        .disabled(true)
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
