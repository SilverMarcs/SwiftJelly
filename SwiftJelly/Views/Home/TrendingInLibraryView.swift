//
//  TrendingInLibraryView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 14/12/2025.
//

import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct TrendingInLibraryView: View {
    @AppStorage("tmdbAPIKey") private var tmdbAPIKey = ""
    @State private var matchedItems: [BaseItemDto] = []
    @State private var scrolledID: String?
    
    private var currentIndex: Int {
        guard let scrolledID else { return 0 }
        return matchedItems.firstIndex { $0.id == scrolledID } ?? 0
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(matchedItems, id: \.id) { item in
                    Group {
                    #if !os(tvOS)
                    MediaNavigationLink(item: item) {
                        hero(item: item)
                    }
                    #else
                    hero(item: item)
                    .frame(height: 1080 * 0.75)
                    .padding(40)
                    .background {
                        if let url = ImageURLProvider.imageURL(for: item, type: .backdrop) {
                            CachedAsyncImage(url: url, targetSize: 2000)
                                .scaledToFill()
                                .overlay {
                                    Rectangle()
                                        .fill(.regularMaterial)
                                        .mask {
                                            LinearGradient(
                                                stops: [
                                                    .init(color: .white, location: 0),
                                                    .init(color: .white.opacity(0.7), location: 0.5),
                                                    .init(color: .white.opacity(0), location: 1)
                                                ],
                                                startPoint: .bottomLeading, endPoint: .topTrailing
                                            )
                                        }
                                }
                        }
                    }
                    #endif
                    }
                    .id(item.id)
                    .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $scrolledID, anchor: .center)
        .scrollTargetBehavior(.viewAligned)
        #if os(tvOS)
        .ignoresSafeArea()
        .contentMargins(.horizontal, 1, for: .scrollContent) // peek tiny bit of next card for scroll to workj
        #endif
        .task(id: tmdbAPIKey) {
            if matchedItems.isEmpty {
                await loadTrendingInLibrary()
            }
        }
        .onChange(of: matchedItems) {
            // Start at 2nd element (index 1) when items load
            if matchedItems.count >= 2 {
                scrolledID = matchedItems[1].id
            }
        }
        #if !os(tvOS)
        .overlay {
            // Navigation chevrons
            if matchedItems.count > 1 {
                HStack {
                    Button {
                        withAnimation {
                            scrollToPrevious()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(currentIndex <= 0)
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            scrollToNext()
                        }
                    } label: {
                        Image(systemName: "chevron.right")
    
                    }
                    .disabled(currentIndex >= matchedItems.count - 1)
                }
                .buttonBorderShape(.circle)
                .buttonStyle(.glass)
                #if os(macOS)
                .controlSize(.large)
                #endif
                .padding(.horizontal, 16)
            }
        }
        #endif
    }
    
    @ViewBuilder
    private func hero(item: BaseItemDto) -> some View {
        switch item.type {
        case .movie:
            MovieHeroView(movie: item)
        case .series:
            ShowHeroView(show: item)
        default:
            EmptyView()
        }
    }
    
    private func scrollToPrevious() {
        guard currentIndex > 0 else { return }
        scrolledID = matchedItems[currentIndex - 1].id
    }
    
    private func scrollToNext() {
        guard currentIndex < matchedItems.count - 1 else { return }
        scrolledID = matchedItems[currentIndex + 1].id
    }

    func loadTrendingInLibrary() async {
        guard let trendingItems = try? await TMDBAPI.fetchTrending(apiKey: tmdbAPIKey) else { return }
        
        var matched: [(Int, BaseItemDto)] = []
        
        await withTaskGroup(of: (Int, BaseItemDto?).self) { group in
            for (index, item) in trendingItems.prefix(20).enumerated() {
                group.addTask { (index, await findMatch(for: item)) }
            }
            for await (index, result) in group {
                if let item = result { matched.append((index, item)) }
            }
        }
        
        // Sort by trending order and deduplicate
        let sorted = matched.sorted { $0.0 < $1.0 }.map { $0.1 }
        let unique = sorted.reduce(into: [BaseItemDto]()) { result, item in
            if !result.contains(where: { $0.id == item.id }) { result.append(item) }
        }
        
        // withAnimation {
            var shuffled = unique.shuffled()
            // Ensure first item is not a series - swap with second if needed
            if shuffled.count >= 2 && shuffled[0].type == .series {
                shuffled.swapAt(0, 1)
            }
            matchedItems = shuffled
        // }
    }
    
    private func findMatch(for trending: TrendingItem) async -> BaseItemDto? {
        guard let results = try? await JFAPI.searchMedia(query: trending.displayTitle) else { return nil }
        let expectedType: BaseItemKind = trending.isMovie ? .movie : .series
        let tmdbID = String(trending.id)
        
        return results.first { item in
            guard item.type == expectedType else { return false }
            if let providers = item.providerIDs, providers["Tmdb"] == tmdbID { return true }
            return item.name?.lowercased() == trending.displayTitle.lowercased()
        }
    }
}
