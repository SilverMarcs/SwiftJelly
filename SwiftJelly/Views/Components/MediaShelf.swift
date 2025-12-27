import SwiftUI
import JellyfinAPI

struct MediaShelf: View {
    let items: [BaseItemDto]
    var header: String
    
    var body: some View {
        SectionContainer(showHeader: !items.isEmpty) {
            HorizontalShelf(spacing: spacing) {
                ForEach(items, id: \.id) { item in
                    MediaNavigationLink(item: item) {
                        MediaCard(item: item)
                    }
                    .frame(width: itemWidth)
                }
            }
        } header: {
            Text(header)
        }
    }
    
    private var itemWidth: CGFloat {
        #if os(tvOS)
        250
        #elseif os(iOS)
        110
        #elseif os(macOS)
        160
        #endif
    }
    
    private var spacing: CGFloat {
        #if os(tvOS)
        40
        #elseif os(iOS)
        12
        #elseif os(macOS)
        16
        #endif
    }
}
