import SwiftUI
import JellyfinAPI
import Kingfisher

struct PortraitImageView: View {
    let item: BaseItemDto
    
    var body: some View {
        KFImage(ImageURLProvider.portraitImageURL(for: item))
            .placeholder {
                Rectangle()
                    .fill(.background.secondary)
                    .overlay {
                        ProgressView()
                    }
            }
            .resizable()
            .aspectRatio(2/3, contentMode: .fill)
    }
}
