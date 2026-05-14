import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct PortraitImageView<Placeholder: View>: View {
    let item: BaseItemDto?
    let placeholder: () -> Placeholder
    
    public init(
        item: BaseItemDto?,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.item = item
        self.placeholder = placeholder
    }

    // Default placeholder
    public init(item: BaseItemDto?) where Placeholder == EmptyView {
        self.item = item
        self.placeholder = { EmptyView() }
    }

    var body: some View {
        CachedAsyncImage(url: imageURL, targetSize: 500, placeholder: placeholder)
            .aspectRatio(1/1.5, contentMode: .fill)
    }
    
    private var imageURL: URL? {
        if let item {
            ImageURLProvider.imageURL(for: item, type: .primary)
        } else {
            nil
        }
    }
}
