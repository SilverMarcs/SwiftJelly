//
//  MediaNavigationLink.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import JellyfinAPI

struct FilteredMediaViewNavItem: Hashable {
    let item: BaseItemDto
}

struct MediaNavigationLink<Label: View>: View {
    let item: BaseItemDto
    @ViewBuilder let label: () -> Label
    
    private var navigationValue: any Hashable {
        item.type == .boxSet ? FilteredMediaViewNavItem(item: item) : item
    }
    
    var body: some View {
        NavigationLink(value: navigationValue) {
            label()
        }
        .adaptiveButtonStyle()
    }
}

// TODO: fix teh namespace errors
struct MediaNavigationDestinationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: BaseItemDto.self) { item in
                destinationView(for: item)
            }
            .navigationDestination(for: BaseItemPerson.self) { person in
                PersonMediaView(person: person)
            }
            .navigationDestination(for: FilteredMediaViewNavItem.self) { item in
                FilteredMediaView(filter: .library(item.item))
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
