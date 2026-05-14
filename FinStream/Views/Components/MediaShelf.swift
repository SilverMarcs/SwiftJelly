import SwiftUI
import JellyfinAPI

struct MediaShelf<Destination: View>: View {
    let header: String
    let loadItemsAction: @Sendable () async throws -> [BaseItemDto]
    private let destination: (() -> Destination)?

    @State private var items: [ViewListItem<BaseItemDto>] = withPlaceholderItems(size: 40)
    @State private var isLoading = false
    @State private var dataLoaded = false
    @State private var showPlaceholder = true

    init(
        header: String,
        loadItemsAction: @escaping @Sendable () async throws -> [BaseItemDto],
        @ViewBuilder destination: @escaping () -> Destination
    ) {
        self.header = header
        self.loadItemsAction = loadItemsAction
        self.destination = destination
    }

    fileprivate init(
        header: String,
        loadItemsAction: @escaping @Sendable () async throws -> [BaseItemDto],
        destination: (() -> Destination)?
    ) {
        self.header = header
        self.loadItemsAction = loadItemsAction
        self.destination = destination
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
                if let destination, hasResolvedItems {
                    NavigationLink {
                        destination()
                    } label: {
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
            if let destination {
                NavigationLink {
                    destination()
                } label: {
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

extension MediaShelf where Destination == EmptyView {
    init(
        header: String,
        loadItemsAction: @escaping @Sendable () async throws -> [BaseItemDto]
    ) {
        self.init(header: header, loadItemsAction: loadItemsAction, destination: nil)
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
