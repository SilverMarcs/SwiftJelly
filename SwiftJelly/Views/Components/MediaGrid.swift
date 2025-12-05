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
    
    #if os(tvOS)
    private let columns = [
        GridItem(.adaptive(minimum: 220), spacing: 48)
    ]
    private let verticalSpacing: CGFloat = 48
    #elseif os(macOS)
    private let columns = [
        GridItem(.adaptive(minimum: 140), spacing: 12)
    ]
    private let verticalSpacing: CGFloat = 16
    #else
    private let columns = [
        GridItem(.adaptive(minimum: 105), spacing: 12)
    ]
    private let verticalSpacing: CGFloat = 16
    #endif
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: verticalSpacing) {
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
            #if os(tvOS)
            .padding(.top, 20)
            #endif
        }
        .overlay {
            if isLoading {
                UniversalProgressView()
            } else if items.isEmpty {
                ContentUnavailableView.search
            }
        }
    }
}
