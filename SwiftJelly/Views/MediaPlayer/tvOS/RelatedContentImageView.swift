import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct RelatedContentImageView: View {
    let item: BaseItemDto

    var body: some View {
        CachedAsyncImage(url: imageURL, targetSize: 1200)
            .aspectRatio(16 / 9, contentMode: .fill)
            .clipShape(.rect(cornerRadius: 16))
    }

    private var imageURL: URL? {
        ImageURLProvider.imageURL(for: item, type: .thumb)
    }
}
