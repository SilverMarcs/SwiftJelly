import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

/// One viewport-sized artwork layer supplies the sidebar extension for the selected slide.
/// Keep this outside the horizontal pager so the effect never mirrors its full content width.
struct HeroCarouselSidebarBackdrop: View {
    let item: BaseItemDto

    var body: some View {
        Color.clear
            .overlay {
                CachedAsyncImage(
                    url: ImageURLProvider.imageURL(for: item, type: .backdrop),
                    targetSize: 1500
                )
                .scaledToFill()
            }
            .overlay {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.9)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .clipped()
            .backgroundExtensionEffect()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

