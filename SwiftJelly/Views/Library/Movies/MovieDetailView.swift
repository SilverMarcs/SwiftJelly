import SwiftUI
import JellyfinAPI

struct MovieDetailView: View {
    let id: String
    @State private var movie: BaseItemDto?
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            if let movie {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        LandscapeImageView(item: movie)
                            .frame(maxHeight: 500)
                    }
                    .backgroundExtensionEffect()
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 8) {
                            LogoView(item: movie)

                            AttributesView(item: movie)
                                .padding(.leading, 2)
                            
                            MoviePlayButton(item: movie)
                                .animation(.default, value: movie)
                                .environment(\.refresh, fetchMovie)
                        }
                        .padding(16)
                    }
                
                    VStack(alignment: .leading, spacing: 5) {
                        if let firstTagline = movie.taglines?.first {
                            Text(firstTagline)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.leading)
                        }
                        
                        if let overview = movie.overview {
                            Text(overview)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .scenePadding(.horizontal)
                    
                    if let people = movie.people {
                        PeopleScrollView(people: people)
                    }
                    
//                    if let studios = movie.studios, !studios.isEmpty {
//                        StudiosScrollView(studios: studios)
//                    }
                    
                    SimilarItemsView(item: movie)
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
        .navigationTitle(movie?.name ?? "Movie")
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
        .task {
            if movie == nil {
                await fetchMovie()
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
            movie = try await JFAPI.loadItem(by: id)
        } catch {
            // handle error
            movie = nil
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
