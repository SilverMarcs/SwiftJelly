import SwiftUI
import JellyfinAPI

struct MovieHeroActions: View {
    let movie: BaseItemDto

    @Namespace private var actionButtonsNamespace

    var body: some View {
        HStack(spacing: spacing) {
            MoviePlayButton(item: movie)
                .prefersDefaultFocus(in: actionButtonsNamespace)

            #if os(tvOS)
            HeroInfoButton(item: movie)
            #endif

            MarkPlayedButton(item: movie)

            FavoriteButton(item: movie)
        }
        .focusScope(actionButtonsNamespace)
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
