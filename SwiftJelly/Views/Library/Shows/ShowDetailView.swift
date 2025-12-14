import SwiftUI
import JellyfinAPI

import SwiftUI
import JellyfinAPI

struct ShowDetailView: View {
    @State private var vm: ShowDetailViewModel
    
    init(item: BaseItemDto) {
        self._vm = State(initialValue: ShowDetailViewModel(item: item))
    }
    
    var body: some View {
        DetailView(item: vm.show) {
            ShowSeasonsView(vm: vm)
            
            PeopleScrollView(people: vm.show.people)
            
            SimilarItemsView(item: vm.show)
        } heroView: {
            ShowHeroView(show: vm.show)
        }
        .navigationTitle("")
        .environment(\.refresh, {
            await vm.loadSeasonsAndEpisodes()
        })
        .task {
            await vm.loadShowDetail()
            await vm.loadSeasonsAndEpisodes()
        }
        .refreshToolbar {
            await vm.loadShowDetail()
            await vm.loadSeasonsAndEpisodes()
        }
    }
}
