import SwiftUI
import JellyfinAPI

struct MovieDetailView: View {
    @State private var movie: BaseItemDto

    init(item: BaseItemDto) {
        self._movie = State(initialValue: item)
    }
    
    var body: some View {
        DetailView(item: movie) {
            VStack(spacing: spacing) {
                PeopleScrollView(people: movie.people)
                
                SimilarItemsView(item: movie)
                
                TMDBReviewsView(item: movie)
            }
        } heroView: {
            MovieHeroView(movie: $movie)
        }
        .refreshToolbar {
            await fetchMovie()
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
    
    private var spacing: CGFloat {
        #if os(tvOS)
        100
        #else
        30
        #endif
    }
}
