import SwiftUI
import JellyfinAPI

struct EpisodeDetailView: View {
    @State private var vm: EpisodeDetailViewModel

    init(item: BaseItemDto) {
        self._vm = State(initialValue: EpisodeDetailViewModel(item: item))
    }

    var body: some View {
        DetailView(item: vm.episode) {
            VStack(spacing: spacing) {
                PeopleScrollView(people: vm.episode.people ?? [])
            }
        } heroView: {
            EpisodeHeroDetailView(vm: vm)
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
                DownloadButton(item: vm.episode)
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
