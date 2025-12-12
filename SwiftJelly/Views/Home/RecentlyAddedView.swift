import SwiftUI
import JellyfinAPI

struct RecentlyAddedView: View {
    let items: [BaseItemDto]
    var header: String
    
    var body: some View {
        if !items.isEmpty {
            #if os(tvOS)
            Section(header) {
                scrollView
                    .scrollClipDisabled()
            }
            #else
            VStack(alignment: .leading, spacing: 8) {
                Text(header)
                    .font(.title3.bold())
                    .scenePadding(.horizontal)

                scrollView
            }
            #endif
        }
    }
    
    var scrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                ForEach(items, id: \.id) { item in
                    MediaNavigationLink(item: item)
                        .frame(width: itemWidth)
                }
            }
            #if !os(tvOS)
            .scenePadding(.horizontal)
            #endif
        }
    }
    
    private var itemWidth: CGFloat {
        #if os(tvOS)
        250
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
