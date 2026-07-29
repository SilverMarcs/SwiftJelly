//
//  MediaDestinationView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/09/2025.
//

import SwiftUI
import JellyfinAPI

struct MediaDestinationView: View {
    #if os(iOS)
    @Environment(\.detailZoomNamespace) private var detailZoomNamespace
    #endif

    let item: BaseItemDto

    var body: some View {
        destinationContent
        #if os(iOS)
            .zoomTransitionDestination(sourceID: item.id ?? "", in: detailZoomNamespace)
        #endif
    }

    @ViewBuilder
    private var destinationContent: some View {
        switch item.type {
        case .movie:
            MovieDetailView(item: item)
        case .series:
            ShowDetailView(item: item)
        case .genre:
            FilteredMediaView(filter: .genre(item.name ?? ""))
        case .episode:
            EpisodeDetailView(item: item)
        case .person:
            FilteredMediaView(filter: .person(id: item.id ?? "", name: item.name ?? "Person"))
        case .collectionFolder, .boxSet:
            FilteredMediaView(filter: .library(item))
        default:
            ContentUnavailableView(
                "Unsupported Media Type",
                systemImage: "questionmark.circle",
                description: Text("Cannot display \(item.type?.rawValue.capitalized ?? "unknown") items")
            ).focusable(true)
        }
    }
}
