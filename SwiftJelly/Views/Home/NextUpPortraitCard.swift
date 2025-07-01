import SwiftUI
import JellyfinAPI

struct NextUpPortraitCard: View {
    let item: BaseItemDto
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif
    @State private var showPlayer = false

    var body: some View {
        Button {
            #if os(macOS)
            openWindow(id: "media-player", value: item)
            #else
            showPlayer = true
            #endif
        } label: {
            VStack(alignment: .leading) {
                AsyncImage(url: showPortraitURL) { image in
                    image
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fill)
                } placeholder: {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: 120, height: 180)
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
            .frame(width: 120)
        }
        .buttonStyle(.plain)
        #if !os(macOS)
        .fullScreenCover(isPresented: $showPlayer) {
            MediaPlayerView(item: item)
        }
        #endif
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
