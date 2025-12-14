import SwiftUI
import JellyfinAPI

struct ShowDetailView: View {
    private let series: BaseItemDto
    let showFullContent: Bool
    @State private var vm: ShowDetailViewModel?
    
    init(item: BaseItemDto, showFullContent: Bool = true) {
        // TODO: init vm here and not keep reference to series at all. do ladoing in task
        self.series = item
        self.showFullContent = showFullContent
    }
    
    var body: some View {
        if let vm = vm {
            detailContent(vm: vm)
        } else {
            UniversalProgressView()
                .task {
                    guard let seriesId = series.id,
                          let fullSeries = try? await JFAPI.loadItem(by: seriesId) else { return }
                    let viewModel = ShowDetailViewModel(item: fullSeries)
                    await viewModel.loadSeasonsAndEpisodes()
                    vm = viewModel
                }
        }
    }
    
    private func detailContent(vm: ShowDetailViewModel) -> some View {
        DetailView(item: vm.show) {
            if showFullContent {
                ShowSeasonsView(vm: vm)
                
                if let people = vm.show.people {
                    PeopleScrollView(people: people)
                }
                
                SimilarItemsView(item: vm.show)
            }

        } itemDetailContent: {
            HStack(spacing: spacing) {
                ShowPlayButton(vm: vm)
                
                if let season = vm.selectedSeason {
                    MarkPlayedButton(item: season)
                        .animation(.snappy, value: vm.selectedSeason)
                }
                
                FavoriteButton(item: vm.show)
            }
        }
        .environment(\.refresh, { [weak vm = vm] in
            await vm?.loadSeasonsAndEpisodes()
        })
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

