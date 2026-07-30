import SwiftUI
import JellyfinAPI

struct MovieHeroActions: View {
    @Binding var movie: BaseItemDto

    /// When provided, the hero's focus scope uses this namespace so a parent can
    /// bias default focus onto the Play button.
    var externalFocusNamespace: Namespace.ID? = nil

    /// When provided, lets a parent programmatically move focus onto the Play
    /// button (e.g. when the hero scrolls back into view).
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
