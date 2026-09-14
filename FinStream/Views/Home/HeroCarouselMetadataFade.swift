import SwiftUI

struct HeroCarouselMetadataFade: ViewModifier {
    let opacity: Double
    let isCarousel: Bool

    func body(content: Content) -> some View {
        content
            .transaction { transaction in
                // Adding the selected slide's controls or loading its logo must not
                // interpolate the metadata stack's layout alongside the page animation.
                if isCarousel { transaction.animation = nil }
            }
            .opacity(opacity)
            .animation(.linear(duration: 0.18), value: opacity)
    }
}

