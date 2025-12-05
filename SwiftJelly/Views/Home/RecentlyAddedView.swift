import SwiftUI
import JellyfinAPI

struct RecentlyAddedView: View {
    let items: [BaseItemDto]
    var header: String
    
    #if os(tvOS)
    private let itemWidth: CGFloat = 220
    private let spacing: CGFloat = 40
    private let headerSpacing: CGFloat = 16
    #else
    private let itemWidth: CGFloat = 150
    private let spacing: CGFloat = 12
    private let headerSpacing: CGFloat = 8
    #endif
    
    var body: some View {
        Group {
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: headerSpacing) {
                    Text(header)
                        #if os(tvOS)
                        .font(.title3)
                        .fontWeight(.bold)
                        #else
                        .font(.title2)
                        .bold()
                        .scenePadding(.leading)
                        #endif

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: spacing) {
                            ForEach(items, id: \.id) { item in
                                MediaNavigationLink(item: item)
                                    .frame(width: itemWidth)
                            }
                        }
                    }
                    #if os(tvOS)
                    .scrollClipDisabled()
                    #endif
                }
            }
        }
    }
}
