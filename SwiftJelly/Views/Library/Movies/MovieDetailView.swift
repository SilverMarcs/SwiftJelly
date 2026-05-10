import SwiftUI
import JellyfinAPI

struct MovieDetailView: View {
    @State private var vm: MovieDetailViewModel

    init(item: BaseItemDto) {
        self._vm = State(initialValue: MovieDetailViewModel(item: item))
    }

    var body: some View {
        DetailView(item: vm.movie) {
            VStack(spacing: spacing) {
                PeopleScrollView(people: vm.movie.people ?? [])

                SimilarItemsView(item: vm.movie)
            }
        } heroView: {
            MovieDetailHeroView(vm: vm)
        }
        .environment(\.refresh, vm.refresh)
        .task {
            await vm.refresh()
        }
        .refreshToolbar {
            await vm.refresh()
        }
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                DownloadButton(item: vm.movie)
            }
        }
        #endif
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        200
        #else
        30
        #endif
    }
}
