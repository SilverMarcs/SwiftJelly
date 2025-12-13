import SwiftUI
import JellyfinAPI

struct ShowDetailView: View {
    private let series: BaseItemDto
    @State private var vm: ShowDetailViewModel?
    
    init(item: BaseItemDto) {
        self.series = item
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
    
    @ViewBuilder
    private func detailContent(vm: ShowDetailViewModel) -> some View {
        DetailView(item: vm.show) {
            ShowSeasonsView(vm: vm)
            
            if let people = vm.show.people {
                PeopleScrollView(people: people)
            }
            
            SimilarItemsView(item: vm.show)

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

