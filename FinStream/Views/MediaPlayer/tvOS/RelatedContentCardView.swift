import SwiftUI
import JellyfinAPI

struct RelatedContentCardView: View {
    let item: BaseItemDto

    var body: some View {
        LandscapeImageView(item: item)
            .clipShape(.rect(cornerRadius: 16))
    }
}
