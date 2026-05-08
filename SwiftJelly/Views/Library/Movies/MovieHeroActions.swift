import SwiftUI
import JellyfinAPI

struct MovieHeroActions: View {
    let movie: BaseItemDto

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
#if os(tvOS)
        .focusScope(actionButtonsNamespace)
#endif
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
