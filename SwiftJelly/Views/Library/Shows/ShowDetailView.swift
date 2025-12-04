import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct ShowDetailView: View {
    private var vm: ShowDetailViewModel

#if os(tvOS)
    private var spacing: CGFloat = 15
#else
    private var spacing: CGFloat = 4
#endif
    
    init(item: BaseItemDto) {
        vm = ShowDetailViewModel(item: item)
    }
    
    var body: some View {
        DetailView(item: vm.show, action: {}) {
            VStack {
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
            }
        } itemDetailContent: {
            HStack(spacing: spacing) {
                ShowPlayButton(vm: vm)
                MarkPlayedButton(item: vm.selectedSeason ?? BaseItemDto())
                
                #if os(tvOS)
                FavoriteButton(item: vm.show)
                    .environment(\.refresh, { [weak vm = vm] in
                        await vm?.reloadSeasonsAndEpisodes()
                    })
                #endif
            }
        }
        .task { await vm.reloadSeasonsAndEpisodes() }
    }
}
