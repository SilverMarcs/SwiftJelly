import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct ShowDetailView: View {
    private var vm: ShowDetailViewModel
    
    init(item: BaseItemDto) {
        vm = ShowDetailViewModel(item: item)
    }
    
    var body: some View {
        DetailView(item: vm.show, action: {}) {
            VStack {
                ShowSeasonsView(vm: vm)
                    .padding(.leading, 80)
                    .padding(.top, 48)
                    .focusSection()
                
                if let people = vm.show.people {
                    PeopleScrollView(people: people)
                        .padding(.leading, 80)
                        .padding(.top, 48)
                        .focusSection()
                }
                
                SimilarItemsView(item: vm.show)
                    .padding(.leading, 80)
                    .padding(.top, 48)
                    .padding(.bottom, 80)
                    .focusSection()
            }
        } itemDetailContent: {
            HStack(spacing: 16) {
                ShowPlayButton(vm: vm)
                MarkPlayedButton(item: vm.selectedSeason ?? BaseItemDto())
                FavoriteButton(item: vm.show)
                    .environment(\.refresh, { [weak vm = vm] in
                        await vm?.reloadSeasonsAndEpisodes()
                    })
            }
        }
        .task { await vm.reloadSeasonsAndEpisodes() }
    }
}
