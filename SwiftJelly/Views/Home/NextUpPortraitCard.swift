import SwiftUI
import JellyfinAPI

struct NextUpPortraitCard: View {
    let item: BaseItemDto

    var body: some View {
        PlayMediaButton(item: item) {
            VStack(alignment: .leading) {
                AsyncImage(url: showPortraitURL) { image in
                    image
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fill)
                } placeholder: {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: 144, height: 216)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(item.seriesName ?? item.album ?? "Unknown Show")
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if let season = item.parentIndexNumber, let episode = item.indexNumber {
                    Text("S\(season)E\(episode)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 144)
        }
        .buttonStyle(.plain)
    }
    
    private var showPortraitURL: URL? {
        if let seriesId = item.seriesID {
            // Try to get portrait image for the show (series)
            var dummyShow = item
            dummyShow.id = seriesId
            return ImageURLProvider.portraitImageURL(for: dummyShow)
        }
        return ImageURLProvider.portraitImageURL(for: item)
    }
}
