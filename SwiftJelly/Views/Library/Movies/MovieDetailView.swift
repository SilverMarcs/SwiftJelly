import SwiftUI
import JellyfinAPI

struct MovieDetailView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var movie: BaseItemDto
    @State private var isLoading = false
    
    init(item: BaseItemDto) {
        self._movie = State(initialValue: item)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Group {
                    if horizontalSizeClass == .compact {
                        PortraitImageView(item: movie)
                    } else {
                        LandscapeImageView(item: movie)
                            .frame(maxHeight: 450)
                    }
                }
                #if os(macOS)
                .backgroundExtensionEffect()
                #else
                .stretchy()
                #endif
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 8) {
                        AttributesView(item: movie)
                            .padding(.leading, 1)
                        
                        MoviePlayButton(item: movie)
                            .environment(\.refresh, fetchMovie)
                    }
                    .padding(16)
                }
            
                OverviewView(item: movie)
                
                if let people = movie.people {
                    PeopleScrollView(people: people)
                }
                
                // TODO: show filteredmeidaview links for genres and studios
                
                SimilarItemsView(item: movie)
            }
            .scenePadding(.bottom)
            .contentMargins(.horizontal, 18)
        }
        .overlay {
            if isLoading {
                UniversalProgressView()
            }
        }
        .refreshable { await fetchMovie() }
        .ignoresSafeArea(edges: .top)
        .navigationTitle(movie.name ?? "Movie")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                FavoriteButton(item: movie)
            }
            #if os(macOS)
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        isLoading = true
                        await fetchMovie()
                        isLoading = false
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .keyboardShortcut("r")
            }
            #endif
        }
        .environment(\.refresh, fetchMovie)
    }
    
    private func fetchMovie() async {
        do {
            movie = try await JFAPI.loadItem(by: movie.id ?? "")
        } catch {
            print("Error loading Movie Detail: \(error.localizedDescription)")
        }
    }
}
