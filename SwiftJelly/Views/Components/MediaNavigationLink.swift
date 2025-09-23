//
//  MediaNavigationLink.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import JellyfinAPI

struct MediaNavigationLink: View {
    let item: BaseItemDto
    
    var body: some View {
        NavigationLink {
            switch item.type {
            case .movie:
                MovieDetailView(item: item)
            case .series:
                ShowDetailView(id: item.id ?? "")
            case .boxSet:
                FilteredMediaView(filter: .library(item))
            default:
                Text("Unsupported item type")
            }
        } label: {
            MediaCard(item: item)
        }
        .buttonStyle(.plain)
    }
}
