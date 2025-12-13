import SwiftUI
import JellyfinAPI

struct MediaShelf: View {
    let items: [BaseItemDto]
    var header: String
    
    var body: some View {
        if !items.isEmpty {
            SectionContainer(header) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing) {
                        ForEach(items, id: \.id) { item in
                            MediaNavigationLink(item: item) {
                                MediaCard(item: item)
                            }
                            .frame(width: itemWidth)
                        }
                    }
                    #if !os(tvOS)
                    .scenePadding(.horizontal)
                    #endif
                }
            }
        }
    }

    private var itemWidth: CGFloat {
        #if os(tvOS)
        250
        #elseif os(iOS)
        125
        #else
        150
        #endif
    }
    
    private var spacing: CGFloat {
        #if os(tvOS)
        40
        #else
        12
        #endif
    }
}
