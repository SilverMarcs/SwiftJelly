//
//  ContinueWatchingView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import JellyfinAPI

struct ContinueWatchingView: View {
    @State private var items: [ViewListItem<BaseItemDto>] = withPlaceholderItems(size: 10)
    @State private var isLoading = false
    
    let header: String
    let loadItemsAction: @Sendable () async throws -> [BaseItemDto]

    var body: some View {
        SectionContainer {
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
    
    private func fetchContinueWatching() async {
        guard !isLoading else { return }
        isLoading = true

        do {
            let loadedItems = try await loadItemsAction()
            withAnimation {
                items.update(with: loadedItems)
                isLoading = false
            }
        } catch {
            print("Error loading Home items: \(error)")
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
