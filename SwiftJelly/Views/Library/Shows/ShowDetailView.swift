import SwiftUI
import JellyfinAPI

struct ShowDetailView: View {
    @State private var show: BaseItemDto
    @State private var isLoading = false
    @State private var refreshTrigger = UUID()
    
    init(item: BaseItemDto) {
        self._show = State(initialValue: item)
    }
    
    var body: some View {
        ScrollView {
            if show.type == .series {
                VStack(alignment: .leading, spacing: 20) {
                    LandscapeImageView(item: show)
                    .frame(maxHeight: 450)
                    .backgroundExtensionEffect()
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 8) {
                            AttributesView(item: show)
                                .padding(.leading, 1)
                            
                            ShowPlayButton(show: show)
                                .environment(\.refresh, fetchShow)
                                .id("show-play-\(refreshTrigger)")
                        }
                        .padding(16)
                    }
                    
                    OverviewView(item: show)

                    ShowSeasonsView(show: show)
                        .environment(\.refresh, fetchShow)
                    
                    if let people = show.people {
                        PeopleScrollView(people: people)
                    }
                    
                    // TODO: show filteredmeidaview links for genres and studios
            
                    SimilarItemsView(item: show)
                }
                .scenePadding(.bottom)
                .contentMargins(.horizontal, 18)
            }
        }
        .overlay {
            if isLoading {
                UniversalProgressView()
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationTitle(show.name ?? "Show")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await fetchShow() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .refreshable {
            await fetchShow()
        }
    }
    
    private func fetchShow() async {
        refreshTrigger = UUID()
        isLoading = true
        defer { isLoading = false }
        do {
            let itemId = show.type == .episode ? (show.seriesID ?? "") : (show.id ?? "")
            show = try await JFAPI.loadItem(by: itemId)
        } catch {
            print(error.localizedDescription)
        }
    }
}
