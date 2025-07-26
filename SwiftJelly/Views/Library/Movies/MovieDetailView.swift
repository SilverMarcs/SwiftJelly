import SwiftUI
import JellyfinAPI

struct MovieDetailView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let id: String
    @State private var movie: BaseItemDto?
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            if let movie {
                VStack(alignment: .leading, spacing: 16) {
                    Group {
                        if horizontalSizeClass == .compact {
                            PortraitImageView(item: movie)
                        } else {
                            LandscapeImageView(item: movie)
                                .frame(maxHeight: 500)
                        }
                    }
                    .backgroundExtensionEffect()
                    .overlay(alignment: .bottomLeading) {
                        MoviePlayButton(item: movie)
                            .animation(.default, value: movie)
                            .environment(\.refresh, fetchMovie)
                            .padding(16)
                    }
                
                    VStack(alignment: .leading, spacing: 12) {
                        if let overview = movie.overview {
                            Text(overview)
                                .foregroundStyle(.secondary)
                        }
                        if let year = movie.productionYear {
                            Text("Year: \(String(year))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let duration = movie.runTimeTicks {
                            Text("Duration: \(duration / 10_000_000 / 60) min")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .scenePadding(.horizontal)
                    
                    if let people = movie.people {
                        PeopleScrollView(people: people)
                            .contentMargins(.horizontal, 10)
                    }
                }
                .scenePadding(.bottom)
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
