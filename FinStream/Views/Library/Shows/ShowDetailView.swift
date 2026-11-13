import SwiftUI
import JellyfinAPI

struct ShowDetailView: View {
    @State private var vm: ShowDetailViewModel
    @State private var seerRequests = SeerSeriesRequestViewModel()
    
    init(item: BaseItemDto) {
        self._vm = State(initialValue: ShowDetailViewModel(item: item))
    }
    
    var body: some View {
        DetailView(item: vm.show) {
            VStack(spacing: spacing) {
                ShowSeasonsView(vm: vm)

                if seerRequests.showsRequestMore, let requestModel = seerRequests.requestModel {
                    SeerRequestMoreView(model: requestModel)
                }

                #if !os(tvOS)
                TrailersShelfView(item: vm.show)
                #endif

                PeopleScrollView(people: vm.show.people ?? [])
                
                SimilarItemsView(item: vm.show)
            }
        } heroView: {
            ShowDetailHeroView(vm: vm)
        }
        .environment(\.refresh, vm.refreshAll)
        .task {
            await vm.refreshAll()
        }
        .task(id: vm.show.id) {
            await seerRequests.load(for: vm.show)
        }
        .alert("Unable to Mark Season Watched", isPresented: Binding(
            get: { vm.seasonWatchError != nil },
            set: { if !$0 { vm.seasonWatchError = nil } }
        )) {
            Button("OK", role: .cancel) { vm.seasonWatchError = nil }
        } message: {
            Text(vm.seasonWatchError ?? "")
        }
        .refreshToolbar {
            await vm.refreshAll()
        }
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        150
        #else
        30
        #endif
    }
}
