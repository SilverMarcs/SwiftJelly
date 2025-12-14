import SwiftUI
import JellyfinAPI

struct MovieDetailView: View {
    @State private var movie: BaseItemDto

    init(item: BaseItemDto) {
        self._movie = State(initialValue: item)
    }
    
    var body: some View {
        DetailView(item: movie) {
            PeopleScrollView(people: movie.people)
            
            SimilarItemsView(item: movie)
        } heroView: {
            MovieHeroView(movie: movie)
        }
        .navigationTitle("")
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
}
