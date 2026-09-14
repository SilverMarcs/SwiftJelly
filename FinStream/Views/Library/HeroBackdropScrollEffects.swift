import SwiftUI

struct HeroBackdropScrollEffects: ViewModifier {
    let isCarousel: Bool

    func body(content: Content) -> some View {
        if isCarousel {
            // Home applies stretch once, outside its horizontal pager. Detail effects here
            // would use the nested scroll coordinate space and duplicate full-size surfaces.
            content
        } else {
            content
                .backgroundExtensionEffect()
                #if os(iOS)
                .stretchy()
                #endif
        }
    }
}

