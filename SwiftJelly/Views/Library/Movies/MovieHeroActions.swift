import SwiftUI
import JellyfinAPI

struct MovieHeroActions: View {
    @Binding var movie: BaseItemDto

    @Namespace private var actionButtonsNamespace

    var body: some View {
        HStack(spacing: spacing) {
            MoviePlayButton(item: movie)
#if os(tvOS)
                .prefersDefaultFocus(in: actionButtonsNamespace)
#endif

            #if os(tvOS)
            HeroInfoButton(item: movie)
            #endif

            MarkPlayedButton(item: movie)

            FavoriteButton(item: movie)
        }
        .redacted(reason: movie.name?.isEmpty == false ? [] : .placeholder)
#if os(tvOS)
        .focusScope(actionButtonsNamespace)
#endif
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

    private var spacing: CGFloat {
        #if os(tvOS)
        15
        #elseif os(macOS)
        8
        #else
        6
        #endif
    }
}
