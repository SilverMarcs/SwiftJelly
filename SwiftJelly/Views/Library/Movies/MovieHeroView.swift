import SwiftUI
import JellyfinAPI

/// A complete standalone hero view for movies with backdrop, overlay, and action buttons.
struct MovieHeroView: View {
    let movie: BaseItemDto
    
    var body: some View {
        HeroBackdropView(item: movie) {
            MovieHeroActions(movie: movie)
        }
    }
}
