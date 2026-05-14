import SwiftUI

struct TrailerCard: View {
    let trailer: Trailer

    var body: some View {
        LandscapeImageView(item: nil, imageURLOverride: trailer.thumbnailURL) {
            Image(systemName: "play.rectangle")
                .font(.title)
                .foregroundStyle(.secondary)
        }
        .frame(width: cardWidth, height: cardWidth * 0.5625, alignment: .center)
        .background(.background.secondary)
        .cardBorder()
    }

    private var cardWidth: CGFloat {
        #if os(tvOS)
        420
        #elseif os(macOS)
        300
        #else
        250
        #endif
    }
}
