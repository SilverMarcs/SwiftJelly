import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct PortraitImageView: View {
    let item: BaseItemDto
    
    var body: some View {
        CachedAsyncImage(url: ImageURLProvider.imageURL(for: item, type: .primary), targetSize: 500)
            .aspectRatio(1/1.5, contentMode: .fill)
    }
}
