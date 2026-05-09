//
//  ContinueWatchingView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import JellyfinAPI

struct ContinueWatchingView: View {
    @AppStorage("continueWatchingStyle") private var continueWatchingStyle: ContinueWatchingStyle = .combined

    var body: some View {
        if continueWatchingStyle == .combined {
            Shelf(header: "Continue Watching") {
                try await JFAPI.loadContinueWatchingSmart()
            }
        } else {
            Shelf(header: "Continue Watching") {
                try await JFAPI.loadResumeItems(limit: 20)
            }

            Shelf(header: "Next Up") {
                try await JFAPI.loadNextUpItems(limit: 20)
            }
        }
    }

    private struct Shelf: View {
        @State private var items: [ViewListItem<BaseItemDto>] = withPlaceholderItems(size: 20)
        @State private var isLoading = false
        @State private var dataLoaded = false
        @State private var showPlaceholder = true

        let header: String
        let loadItemsAction: @Sendable () async throws -> [BaseItemDto]

        var body: some View {
            SectionContainer(
                isVisible: showPlaceholder || hasResolvedItems,
                showHeader: showPlaceholder || hasResolvedItems
            ) {
                HorizontalShelf(spacing: spacing) {
                    ForEach(items, id: \.id) { item in
                        ContinueWatchingCard(
                            item: item.base,
                            imageURLOverride: item.base != nil ? ImageURLProvider.seriesImageURL(for: item.base!) : nil
                        )
                    }
                }
            } header: {
                Text(header)
            }
            .onAppear {
                Task {
                    await fetchContinueWatching()
                }
            }
            .environment(\.refresh, fetchContinueWatching)
        }

        private var hasResolvedItems: Bool {
            items.contains { $0.base != nil }
        }

        private func fetchContinueWatching() async {
            guard !isLoading else { return }
            isLoading = true
            defer { isLoading = false }
            async let placeholderTimeout: Void = hidePlaceholderAfterDelayIfNeeded()

            do {
                let loadedItems = try await loadItemsAction()
                dataLoaded = true

                if !loadedItems.isEmpty {
                    withAnimation {
                        items.update(with: loadedItems)
                    }
                }
            } catch {
                dataLoaded = true
                print("Error loading Home items: \(error)")
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

        private var spacing: CGFloat {
            #if os(tvOS)
            35
            #else
            12
            #endif
        }
    }
}
