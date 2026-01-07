import SwiftUI
import JellyfinAPI

struct MediaShelf: View {
    let header: String
    let loadItemsAction: @Sendable () async throws -> [BaseItemDto]

    @State private var items: [BaseItemDto] = []
    @State private var isLoading = false
    
    var body: some View {
        SectionContainer(showHeader: !items.isEmpty || isLoading) {
            if !items.isEmpty {
                HorizontalShelf(spacing: spacing) {
                    ForEach(items, id: \.id) { item in
                        MediaNavigationLink(item: item) {
                            MediaCard(item: item)
                        }
                        .frame(width: itemWidth)
                    }
                }
            }
            
            if isLoading {
                UniversalProgressView()
            }
        } header: {
            Text(header)
        }
        .task {
            await loadItems()
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
        if !items.isEmpty { return }
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let loadedItems = try await loadItemsAction()
            withAnimation {
                items = loadedItems
            }
        } catch {
            print("Error loading MediaShelf items: \(error)")
        }
    }
}
