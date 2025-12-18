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

    var body: some View {
        SectionContainer("Continue Watching", showHeader: !items.isEmpty) {
            HorizontalShelf(spacing: spacing) {
                ForEach(items, id: \.id) { item in
                    PlayableCard(item: item)
                }
            }
        } destination: {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(items, id: \.id) { item in
                        PlayableCard(item: item)
                    }
                }
                .scenePadding()
            }
            .navigationTitle("Continue Watching")
            .toolbarTitleDisplayMode(.inline)
        }
        .task {
            if items.isEmpty {
                await loadContinueWatching()
            }
        }
        .environment(\.refresh, loadContinueWatching)
    }
    
    private func loadContinueWatching() async {
        do {
            let continueItems = try await JFAPI.loadContinueWatchingSmart()
            withAnimation {
                items = continueItems
            }
        } catch {
            print("Error loading Home items: \(error)")
        }
    }
    
    private var gridColumns: [GridItem] {
        #if os(iOS)
        [GridItem(.flexible())]
        #else
        [GridItem(.adaptive(minimum: 280), spacing: 12)]
        #endif
    }
    
    private var spacing: CGFloat {
        #if os(tvOS)
        40
        #else
        12
        #endif
    }
}
