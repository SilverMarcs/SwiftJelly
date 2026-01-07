//
//  ContinueWatchingView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import JellyfinAPI

struct ContinueWatchingView: View {
    @State private var items: [BaseItemDto] = []
    @State private var isLoading = false

    var body: some View {
        SectionContainer(showHeader: !items.isEmpty || isLoading) {
            if !items.isEmpty {
                HorizontalShelf(spacing: spacing) {
                    ForEach(items, id: \.id) { item in
                        ContinueWatchingCard(
                            item: item,
                            imageURLOverride: ImageURLProvider.seriesImageURL(for: item)
                        )
                    }
                }
            }

            if isLoading {
                UniversalProgressView()
            }
        } header: {
            Text("Continue Watching")
        }
        .task {
            await loadContinueWatching()
        }
        .environment(\.refresh, loadContinueWatching)
    }
    
    private func loadContinueWatching() async {
        if !items.isEmpty { return }
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let continueItems = try await JFAPI.loadContinueWatchingSmart()
            withAnimation {
                items = continueItems
            }
            TopShelfCache.save(items: continueItems)
        } catch {
            print("Error loading Home items: \(error)")
        }
    }
    
    private var gridColumns: [GridItem] {
        #if os(iOS)
        [GridItem(.flexible())]
        #else
        [GridItem(.adaptive(minimum: 250), spacing: 12)]
        #endif
    }
    
    private var spacing: CGFloat {
        #if os(tvOS)
        35
        #else
        12
        #endif
    }

}
