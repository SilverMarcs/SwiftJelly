import SwiftUI
import JellyfinAPI

struct MediaShelf: View {
    let header: String
    let loadItemsAction: @Sendable () async throws -> [BaseItemDto]

    @State private var items: [ViewListItem<BaseItemDto>] = withPlaceholderItems(size: 10)
    @State private var dataLoaded = false
    
    var body: some View {
        SectionContainer(showHeader: !items.isEmpty) {
            HorizontalShelf(spacing: spacing) {
                ForEach(items, id: \.id) { item in
                    MediaNavigationLink(item: item.base) {
                        MediaCard(item: item.base)
                    }
                    .frame(width: itemWidth, height: itemHeight)
                    .id(item.id)
                }
            }
        } header: {
            Text(header)
        }
        .onAppear {
            Task {
                await loadItems()
            }
        }
    }
    
    private var itemWidth: CGFloat {
        #if os(tvOS)
        250
        #elseif os(iOS)
        110
        #elseif os(macOS)
        160
        #endif
    }
    
    private var itemHeight: CGFloat {
        itemWidth * 1.5
    }
    
    private var spacing: CGFloat {
        #if os(tvOS)
        40
        #elseif os(iOS)
        12
        #elseif os(macOS)
        16
        #endif
    }

    private func loadItems() async {
        if dataLoaded { return }

        do {
            let loadedItems = try await loadItemsAction()
            dataLoaded = true

            withAnimation {
                items.update(with: loadedItems)
            }
        } catch {
            print("Error loading MediaShelf items: \(error)")
        }
    }
}
