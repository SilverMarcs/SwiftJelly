import SwiftUI
import JellyfinAPI

struct MediaGrid: View {
    let items: [BaseItemDto]
    let isLoading: Bool
    let onLoadMore: (() -> Void)?
    
    init(items: [BaseItemDto], isLoading: Bool, onLoadMore: (() -> Void)? = nil) {
        self.items = items
        self.isLoading = isLoading
        self.onLoadMore = onLoadMore
    }
    
    private static var defaultSize: CGFloat {
        #if os(macOS)
        140
        #else
        105
        #endif
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: defaultSize), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    MediaNavigationLink(item: item)
                        .onAppear {
                            if item == items.last, let onLoadMore {
                                onLoadMore()
                            }
                        }
                }
            }
            .scenePadding(.horizontal)
            .scenePadding(.bottom)
        }
        .overlay {
            if isLoading {
                UniversalProgressView()
            } else if  items.isEmpty {
                ContentUnavailableView {
                    Label("No Media Found", systemImage: "play.square.stack.fill")
                } description: {
                    Text("Try a different query for your search")
                }
            }
        }
    }
}
