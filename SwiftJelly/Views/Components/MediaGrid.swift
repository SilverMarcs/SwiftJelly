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
    
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: columnMinimumWidth), spacing: columnSpacing)]
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: gridVerticalSpacing) {
                ForEach(items) { item in
                    MediaNavigationLink(item: item) {
                        MediaCard(item: item)
                    }
                    .onAppear {
                        if item == items.last, let onLoadMore {
                            onLoadMore()
                        }
                    }
                }
            }
            .scenePadding()
            
            if isLoading && !items.isEmpty {
                UniversalProgressView()
                    .padding(.vertical, 24)
            }
        }
        .overlay {
            if isLoading && items.isEmpty {
                UniversalProgressView()
            } else if !isLoading && items.isEmpty {
                ContentUnavailableView(
                    "No Media",
                    systemImage: "play.tv",
                    description: Text("Refine search or explore other sections")
                )
            }
        }
    }
    
    private var columnMinimumWidth: CGFloat {
        #if os(tvOS)
        220
        #elseif os(macOS)
        140
        #else
        105
        #endif
    }

    private var columnSpacing: CGFloat {
        #if os(tvOS)
        48
        #elseif os(macOS)
        18
        #else
        12
        #endif
    }

    private var gridVerticalSpacing: CGFloat {
        #if os(tvOS)
        48
        #else
        16
        #endif
    }
}
