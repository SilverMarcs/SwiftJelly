import SwiftUI
import JellyfinAPI

/// A complete standalone hero view for shows with backdrop, overlay, and action buttons.
struct ShowHeroView: View {
    @Binding var show: BaseItemDto
    
    var body: some View {
        HeroBackdropView(item: show) {
            ShowHeroActions(show: $show)
        }
    }
}
