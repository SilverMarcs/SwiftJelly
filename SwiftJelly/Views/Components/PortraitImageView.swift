import SwiftUI
import JellyfinAPI

struct PortraitImageView: View {
    let item: BaseItemDto
    
    var body: some View {
        AsyncImage(url: ImageURLProvider.portraitImageURL(for: item)) { image in
            image
                .resizable()
                .aspectRatio(2/3, contentMode: .fill)
        } placeholder: {
            RoundedRectangle(cornerRadius: 8)
                .overlay {
                    ProgressView()
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
