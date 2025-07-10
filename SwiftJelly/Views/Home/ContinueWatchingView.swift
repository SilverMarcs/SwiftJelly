//
//  ContinueWatchingView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import JellyfinAPI

struct ContinueWatchingView: View {
    let items: [BaseItemDto]

    var body: some View {
        if !items.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(items, id: \.id) { item in
                        PlayableCard(item: item)
                            .contextMenu {
                                NavigationLink {
                                    switch item.type {
                                    case .movie:
                                        MovieDetailView(id: item.id ?? "")
                                    case .episode, .series:
                                        ShowDetailView(id: item.seriesID ?? "")
                                    default:
                                        Text("Unsupported item type")
                                    }
                                } label: {
                                    ItemTypeLabel(item: item)
                                }
                            }
                    }
                }
            }
        }
    }
}

struct ItemTypeLabel: View {
    let item: BaseItemDto
    
    var body: some View {
        switch item.type {
        case .movie:
            Label("Go to Movie", systemImage: "film")
        case .episode:
            Label("Go to Show", systemImage: "play.tv")
        case .series:
            Label("Go to Show", systemImage: "play.tv")
        default:
            Label(item.type?.rawValue.capitalized ?? "Unknown", systemImage: "questionmark.circle")
        }
    }
}
