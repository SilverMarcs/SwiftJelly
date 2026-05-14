import SwiftUI

struct HorizontalShelf<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: spacing) {
                content()
            }
            .scenePadding(.horizontal)
        }
        .scrollIndicators(.hidden)
        #if os(tvOS)
        .scrollClipDisabled()
        #endif
    }
}
