import SwiftUI
import JellyfinAPI

struct MovieHeroActions: View {
    @Binding var movie: BaseItemDto
    var externalFocusNamespace: Namespace.ID? = nil
    var playFocus: FocusState<Bool>.Binding? = nil

    var body: some View {
        HeroActionButtons(
            context: .carousel,
            usesGlassContainer: true,
            infoItem: movie,
            markPlayedItem: movie,
            favoriteItem: movie,
            redactWhenEmpty: movie,
            externalFocusNamespace: externalFocusNamespace,
            playFocus: playFocus
        ) {
            MoviePlayButton(item: movie)
        }
        .environment(\.refresh, refresh)
    }

    private func refresh() async {
        guard let id = movie.id, !id.isEmpty else { return }
        do {
            movie = try await JFAPI.loadItem(by: id)
        } catch {
            print("Error refreshing movie: \(error)")
        }
    }
}
