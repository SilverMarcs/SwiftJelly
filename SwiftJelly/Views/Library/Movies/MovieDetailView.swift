import SwiftUI
import JellyfinAPI

struct MovieDetailView: View {
    @State private var currentItem: BaseItemDto
    @State private var isLoading = false
    
    init(item: BaseItemDto) {
        self._currentItem = State(initialValue: item)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                LandscapeImageView(item: currentItem)
                    .frame(maxHeight: 450)
                .backgroundExtensionEffect()
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 8) {
                        AttributesView(item: currentItem)
                            .padding(.leading, 1)
                        
                        MoviePlayButton(item: currentItem)
                            .animation(.default, value: currentItem)
                            .environment(\.refresh, fetchMovie)
                    }
                    .padding(16)
                }
            
                OverviewView(item: currentItem)
                
                if let people = currentItem.people {
                    PeopleScrollView(people: people)
                }
                
                // TODO: show filteredmeidaview links for genres and studios
                
                SimilarItemsView(item: currentItem)
            }
            .scenePadding(.bottom)
            .contentMargins(.horizontal, 18)
        }
        .overlay {
            if isLoading {
                UniversalProgressView()
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationTitle(currentItem.name ?? "Movie")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await fetchMovie() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .refreshable {
            await fetchMovie()
        }
    }
    
    private func fetchMovie() async {
        isLoading = true
        defer { isLoading = false }
        do {
            currentItem = try await JFAPI.loadItem(by: currentItem.id ?? "")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    var aspectRatio: CGFloat {
        #if os(macOS)
        return 16 / 9
        #else
        return 9 / 13
        #endif
    }
}
