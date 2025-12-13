import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct ShowDetailView: View {
    private var vm: ShowDetailViewModel
    
    init(item: BaseItemDto) {
        vm = ShowDetailViewModel(item: item)
    }
    
    var body: some View {
        DetailView(item: vm.show) {
            ShowSeasonsView(vm: vm)
                #if os(tvOS)
                .focusSection()
                #endif
            
            if let people = vm.show.people {
                PeopleScrollView(people: people)
                    #if os(tvOS)
                    .focusSection()
                    #endif
            }
            
            SimilarItemsView(item: vm.show)
                #if os(tvOS)
                .focusSection()
                #endif
        } itemDetailContent: {
            HStack(spacing: spacing) {
                ShowPlayButton(vm: vm)
                
                if let season = vm.selectedSeason {
                    MarkPlayedButton(item: season)
                        .animation(.snappy, value: vm.selectedSeason) // likely doesnt work
                }
                
                FavoriteButton(item: vm.show)
            }
        }
        .navigationTitle(vm.show.name ?? "")
        .environment(\.refresh, { [weak vm = vm] in
            await vm?.reloadSeasonsAndEpisodes()
        })
        .task { await vm.reloadSeasonsAndEpisodes() }
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
