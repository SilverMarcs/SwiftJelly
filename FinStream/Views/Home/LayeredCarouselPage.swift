import SwiftUI

struct LayeredCarouselPage<Content: View>: View {
    let size: CGSize
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(width: size.width, height: size.height)
            .clipped()
            .compositingGroup()
    }
}

