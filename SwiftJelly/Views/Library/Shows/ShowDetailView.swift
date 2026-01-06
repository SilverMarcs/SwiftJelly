import SwiftUI
import JellyfinAPI

struct ShowDetailView: View {
    @State private var vm: ShowDetailViewModel
    
    init(item: BaseItemDto) {
        self._vm = State(initialValue: ShowDetailViewModel(item: item))
    }
    
    var body: some View {
        DetailView(item: vm.show) {
            VStack(spacing: spacing) {
                ShowSeasonsView(vm: vm)
                
                PeopleScrollView(people: vm.show.people)
                
                SimilarItemsView(item: vm.show)
                
                TMDBReviewsView(item: vm.show)
            }
        } heroView: {
            ShowHeroDetailView(vm: vm)
        }
        .navigationTitle("")
        .environment(\.refresh, vm.refreshAll)
        .task {
            await vm.refreshAll()
        }
        .refreshToolbar {
            await vm.refreshAll()
        }
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        100
        #else
        30
        #endif
    }
}
