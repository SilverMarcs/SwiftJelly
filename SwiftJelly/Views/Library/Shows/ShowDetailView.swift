import SwiftUI
import JellyfinAPI

struct ShowDetailView: View {
    @State private var currentShow: BaseItemDto
    @State private var isLoading = false
//    @State private var refreshTrigger = UUID()
    
    init(item: BaseItemDto) {
        self._currentShow = State(initialValue: item)
    }
    
    var body: some View {
        ScrollView {
            if currentShow.type == .series {
                VStack(alignment: .leading, spacing: 20) {
                    LandscapeImageView(item: currentShow)
                    .frame(maxHeight: 450)
                    .backgroundExtensionEffect()
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 8) {
                            AttributesView(item: currentShow)
                                .padding(.leading, 1)
                            
                            ShowPlayButton(show: currentShow)
                                .environment(\.refresh, fetchShow)
//                                .id("show-play-\(refreshTrigger)")
                        }
                        .padding(16)
                    }
                    
                    OverviewView(item: currentShow)

                    ShowSeasonsView(show: currentShow)
                    
                    if let people = currentShow.people {
                        PeopleScrollView(people: people)
                    }
                    
                    // TODO: show filteredmeidaview links for genres and studios
            
                    SimilarItemsView(item: currentShow)
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
        .navigationTitle(currentShow.name ?? "Show")
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
        isLoading = true
        defer { isLoading = false }
        do {
            let itemId = currentShow.type == .episode ? (currentShow.seriesID ?? "") : (currentShow.id ?? "")
            currentShow = try await JFAPI.loadItem(by: itemId)
        } catch {
            print(error.localizedDescription)
        }
    }
}
