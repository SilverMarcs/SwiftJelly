import SwiftUI
import JellyfinAPI

struct MediaShelf: View {
    let items: [BaseItemDto]
    var header: String
    
    var body: some View {
        SectionContainer(header, showHeader: !items.isEmpty) {
            HorizontalShelf(spacing: spacing) {
                ForEach(items, id: \.id) { item in
                    MediaNavigationLink(item: item) {
                        MediaCard(item: item)
                    }
                }
            }
        } destination: {
            MediaGrid(items: items, isLoading: false)
                .navigationTitle(header)
                .toolbarTitleDisplayMode(.inline)
        }
    }
    
    private var spacing: CGFloat {
        #if os(tvOS)
        40
        #elseif os(macOS)
        12
        #else
        12
        #endif
    }
}
