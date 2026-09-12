import SwiftUI
import JellyfinAPI

struct MediaShelf: View {
    let header: String
    let loadItemsAction: @Sendable () async throws -> [BaseItemDto]
    /// When set, a "See All" affordance pushes `FilteredMediaView(filter:)` via
    /// value-based navigation (the destination is registered by
    /// `navigationRouteDestinations()`). `nil` hides the affordance.
    private let filter: MediaFilter?

    @State private var items: [ViewListItem<BaseItemDto>] = withPlaceholderItems(size: 40)
    @State private var isLoading = false
    @State private var dataLoaded = false
    @State private var showPlaceholder = true

    init(
        header: String,
        filter: MediaFilter? = nil,
        loadItemsAction: @escaping @Sendable () async throws -> [BaseItemDto]
    ) {
        self.header = header
        self.filter = filter
        self.loadItemsAction = loadItemsAction
    }

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

                #if os(tvOS)
                if let filter, hasResolvedItems {
                    NavigationLink(value: NavigationRoute.filter(filter)) {
                        SeeAllCard()
                    }
                    .buttonStyle(.card)
                    .frame(width: itemWidth, height: itemHeight)
                }
                #endif
            }
        } header: {
            #if os(tvOS)
            Text(header)
            #else
            if let filter {
                NavigationLink(value: NavigationRoute.filter(filter)) {
                    HStack(spacing: 4) {
                        Text(header)
                        Image(systemName: "chevron.right")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Text(header)
            }
            #endif
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
        #else
        Device.isMacOrPad ? 165 : 110
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

#if os(tvOS)
private struct SeeAllCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.right.circle")
                .font(.system(size: 64, weight: .light))
            Text("See All")
                .font(.headline)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background.secondary)
        .cardBorder()
    }
}
#endif
