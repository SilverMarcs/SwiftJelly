import SwiftUI
import JellyfinAPI

struct ShowHeroActions: View {
    @State private var vm: ShowDetailViewModel
    
    init(show: BaseItemDto) {
        _vm = State(initialValue: ShowDetailViewModel(item: show))
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            ShowPlayButton(vm: vm)
            
            if let season = vm.selectedSeason {
                MarkPlayedButton(item: season)
            }
            
            FavoriteButton(item: vm.show)
        }
        .environment(\.refresh, vm.refreshAll)
        .task {
            await vm.refreshAll()
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
}
