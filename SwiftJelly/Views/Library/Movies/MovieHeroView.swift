import SwiftUI
import JellyfinAPI

/// A complete standalone hero view for movies with backdrop, overlay, and action buttons.
struct MovieHeroView: View {
    @Binding var movie: BaseItemDto
    
    var body: some View {
        HeroBackdropView(item: movie) {
            MovieHeroActions(movie: movie)
                .environment(\.refresh, refreshMovie)
        }
    }
    
    private func refreshMovie() async {
        guard let id = movie.id, !id.isEmpty else { return }
        do {
            movie = try await JFAPI.loadItem(by: id)
        } catch {
            print("Error refreshing movie: \(error)")
        }
    }
}
