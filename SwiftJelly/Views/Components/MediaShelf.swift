import SwiftUI
import JellyfinAPI

struct MediaShelf: View {
    let header: String
    let loadItemsAction: @Sendable () async throws -> [BaseItemDto]

    @State private var items: [ViewListItem<BaseItemDto>] = withPlaceholderItems(size: 10)
    @State private var isLoading = false
    @State private var dataLoaded = false
    @State private var showPlaceholder = true
    
    var body: some View {
        SectionContainer(
            isVisible: showPlaceholder || hasResolvedItems,
            showHeader: showPlaceholder || hasResolvedItems
        ) {
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
    
    private var hasResolvedItems: Bool {
        items.contains { $0.base != nil }
    }

    private func loadItems() async {
        if dataLoaded { return }
        if isLoading { return }

        isLoading = true
        defer { isLoading = false }
        async let placeholderTimeout: Void = hidePlaceholderAfterDelayIfNeeded()

        do {
            let loadedItems = try await loadItemsAction()
            dataLoaded = true

            if loadedItems.isEmpty {
                // Keep placeholders visible until timeout, then collapse if still unresolved.
            } else {
                withAnimation {
                    items.update(with: loadedItems)
                }
            }
        } catch {
            dataLoaded = true
            print("Error loading MediaShelf items: \(error)")
        }

        await placeholderTimeout

        if hasResolvedItems {
            showPlaceholder = false
        }
    }

    private func hidePlaceholderAfterDelayIfNeeded() async {
        try? await Task.sleep(for: .seconds(10))

        guard !hasResolvedItems else { return }
        withAnimation {
            showPlaceholder = false
        }
    }
}
