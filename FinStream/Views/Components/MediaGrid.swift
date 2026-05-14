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
        [GridItem(.adaptive(minimum: posterWidth), spacing: gridVerticalSpacing)]
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: gridVerticalSpacing) {
                ForEach(items) { item in
                    MediaNavigationLink(item: item) {
                        MediaCard(item: item)
                    }
                    .aspectRatio(2.0 / 3.0, contentMode: .fit)
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
                    .focusable(true)
            } else if !isLoading && items.isEmpty {
                ContentUnavailableView(
                    "No Media",
                    systemImage: "play.tv",
                    description: Text("Refine search or explore other sections")
                )
                .focusable(true)
            }
        }
    }

    private var gridVerticalSpacing: CGFloat {
        #if os(tvOS)
        30
        #elseif os(iOS)
        12
        #elseif os(macOS)
        10
        #endif
    }
}


#Preview {
    MediaGrid(items: [
        BaseItemDto(id: "1"),
        BaseItemDto(id: "2"),
        BaseItemDto(id: "3"),
        BaseItemDto(id: "4"),
        BaseItemDto(id: "5"),
        BaseItemDto(id: "6"),
        BaseItemDto(id: "7"),
        BaseItemDto(id: "8"),
        BaseItemDto(id: "9"),
        BaseItemDto(id: "10"),
        BaseItemDto(id: "11"),
        BaseItemDto(id: "12"),
        BaseItemDto(id: "13"),
        BaseItemDto(id: "14")
    ], isLoading: true)
}
