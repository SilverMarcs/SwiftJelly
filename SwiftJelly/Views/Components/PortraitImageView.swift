import SwiftUI
import JellyfinAPI

struct PortraitImageView: View {
    let item: BaseItemDto
    
    var body: some View {
        CachedImageView(url: ImageURLProvider.portraitImageURL(for: item), targetSize: CGSize(width: 480, height: 720))
            .aspectRatio(2/3, contentMode: .fill)
    }
}
