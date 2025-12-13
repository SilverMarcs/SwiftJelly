import SwiftUI
import JellyfinAPI

struct MovieDetailView: View {
    @State private var movie: BaseItemDto

    init(item: BaseItemDto) {
        self._movie = State(initialValue: item)
    }
    
    var body: some View {
        DetailView(item: movie) {
            if let people = movie.people {
                PeopleScrollView(people: people)
                    #if os(tvOS)
                    .focusSection()
                    #endif
            }
            
            SimilarItemsView(item: movie)
                #if os(tvOS)
                .focusSection()
                #endif
        } itemDetailContent: {
            HStack(spacing: spacing) {
                MovieOrEpisodePlayButton(item: movie)
                
                MarkPlayedButton(item: movie)
                
                if movie.type != .episode {
                    FavoriteButton(item: movie)
                }
            }
        }
//        .navigationTitle(movie.name ?? "")
        .environment(\.refresh, fetchMovie)
    }

    private func fetchMovie() async {
        do {
            movie = try await JFAPI.loadItem(by: movie.id ?? "")
        } catch {
            print("Error loading Movie Detail: \(error.localizedDescription)")
        }
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
