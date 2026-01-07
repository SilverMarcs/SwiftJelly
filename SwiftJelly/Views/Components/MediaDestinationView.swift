//
//  MediaDestinationView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/09/2025.
//

import SwiftUI
import JellyfinAPI

struct MediaDestinationView: View {
    let item: BaseItemDto

    var body: some View {
        switch item.type {
        case .movie:
            MovieDetailView(item: item)
        case .series:
            ShowDetailView(item: item)
        case .episode:
            ShowDetailView(item: BaseItemDto(id: item.seriesID))
        case .person:
            FilteredMediaView(filter: .person(id: item.id ?? "", name: item.name ?? "Person"))
        case .collectionFolder, .boxSet:
            FilteredMediaView(filter: .library(item))
        default:
            ContentUnavailableView(
                "Unsupported Media Type",
                systemImage: "questionmark.circle",
                description: Text("Cannot display \(item.type?.rawValue.capitalized ?? "unknown") items")
            )
        }
    }
}
