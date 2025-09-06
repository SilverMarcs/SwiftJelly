import SwiftUI
import JellyfinAPI

struct MediaGrid: View {
    let items: [BaseItemDto]
    let isLoading: Bool
    
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
