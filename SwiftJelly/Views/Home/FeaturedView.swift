//
//  FeaturedView.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 11.02.26.
//

import SwiftUI
import SwiftMediaViewer
import JellyfinAPI

/// Loads a list of items via the supplied closure and renders them in the
/// shared `HeroCarouselView` (same look & behavior as `TrendingInLibraryView`).
struct FeaturedView: View {
    let loadItemsAction: @Sendable () async throws -> [BaseItemDto]

    @State private var items: [BaseItemDto] = []
    @State private var hasStartedLoading = false

    var body: some View {
        Group {
            if !items.isEmpty {
                HeroCarouselView(items: $items)
            } else {
                HeroBackdropView(item: BaseItemDto()) {}
            }
        }
        .task {
            guard !hasStartedLoading else { return }
            hasStartedLoading = true
            await load()
        }
    }

    private func load() async {
        do {
            let loaded = try await loadItemsAction()
            let filtered = loaded.filter { $0.type == .movie || $0.type == .series }
            await MainActor.run {
                withAnimation { items = filtered }
            }
        } catch {
            print("Error loading featured items: \(error)")
        }
    }
}
