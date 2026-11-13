//
//  SeerRequestsShelf.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI

struct SeerRequestsShelf: View {
    @State private var items: [ViewListItem<SeerRequestItem>] = withPlaceholderItems(size: 6)
    @State private var hasLoaded = false

    var body: some View {
        if SeerAPI.isConfigured {
            SectionContainer(isVisible: !hasLoaded || hasResolvedItems) {
                HorizontalShelf(spacing: spacing) {
                    ForEach(items) { item in
                        SeerRequestCard(requestItem: item.base)
                    }
                }
            } header: {
                Text("Requests")
            }
            .task {
                await load()
            }
            .environment(\.refresh, load)
        }
    }

    private var hasResolvedItems: Bool {
        items.contains { $0.base != nil }
    }

    private func load() async {
        do {
            let loadedItems = try await SeerAPI.userRequestItems()
            withAnimation {
                items.update(with: loadedItems)
            }
        } catch {
            items = []
            print("Error loading Seer requests: \(error)")
        }
        hasLoaded = true
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        35
        #else
        12
        #endif
    }
}
