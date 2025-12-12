import SwiftUI
import JellyfinAPI

struct RecentlyAddedView: View {
    let items: [BaseItemDto]
    var header: String
    
    var body: some View {
        Group {
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: headerSpacing) {
                    Text(header)
                        .font(.title3.bold())
                        .scenePadding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: spacing) {
                            ForEach(items, id: \.id) { item in
                                MediaNavigationLink(item: item)
                                    .frame(width: itemWidth)
                            }
                        }
                        .scenePadding(.horizontal)
                    }
                    #if os(tvOS)
                    .scrollClipDisabled()
                    #endif
                }
            }
        }
    }
    
    private var itemWidth: CGFloat {
        #if os(tvOS)
        220
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
    
    private var headerSpacing: CGFloat {
        #if os(tvOS)
        16
        #else
        8
        #endif
    }
}
