import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct DetailLogoOverlayView: View {
    let item: BaseItemDto


    var body: some View {
        if let url = ImageURLProvider.imageURL(for: item, type: .logo) {
            CachedAsyncImage(url: url, targetSize: 450)
                .scaledToFit()
                .frame(maxHeight: 120)
                .transition(.opacity)
                .allowsHitTesting(false)
        }
    }
}
