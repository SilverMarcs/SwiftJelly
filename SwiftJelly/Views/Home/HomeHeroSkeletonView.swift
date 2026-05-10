import SwiftUI
import JellyfinAPI

/// Skeleton placeholder for the home hero shown while trending/featured items
/// are still loading. Passes an empty `BaseItemDto` to `HeroBackdropView` —
/// the hero internally renders redacted placeholders for any nil fields.
struct HomeHeroSkeletonView: View {
    var body: some View {
        HeroBackdropView(item: BaseItemDto()) {
            MovieHeroActions(movie: .constant(BaseItemDto()))
                .redacted(reason: .placeholder)
        }
        .disabled(true)
    }
}
