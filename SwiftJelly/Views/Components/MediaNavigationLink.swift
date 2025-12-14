//
//  MediaNavigationLink.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import JellyfinAPI

struct MediaNavigationLink<Label: View>: View {
    let item: BaseItemDto
    @ViewBuilder let label: () -> Label
    
    var body: some View {
        NavigationLink(value: item) {
            label()
        }
        .adaptiveButtonStyle()
    }
}

struct MediaNavigationDestinationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: BaseItemDto.self) { item in
                destinationView(for: item)
            }
            .navigationDestination(for: BaseItemPerson.self) { person in
                FilteredMediaView(filter: .person(person))
            }
    }
    
    @ViewBuilder
    private func destinationView(for item: BaseItemDto) -> some View {
        switch item.type {
        case .movie:
            MovieDetailView(item: item)
        case .series:
            ShowDetailView(item: item)
        case .episode:
            ShowDetailView(item: BaseItemDto(id: item.seriesID))
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

extension View {
    public func navigationDestinations() -> some View {
        modifier(MediaNavigationDestinationModifier())
    }
}
