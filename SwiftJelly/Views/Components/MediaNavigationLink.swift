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

struct MediaNavigationLink: View {
    let item: BaseItemDto
    @Environment(\.zoomNamespace) private var animationID
    
    private var navigationValue: any Hashable {
        item.type == .boxSet ? FilteredMediaViewNavItem(item: item) : item
    }
    
    var body: some View {
        NavigationLink(value: navigationValue) {
            MediaCard(item: item)
        }
        #if os(tvOS)
        .buttonStyle(.borderless)
        #else
        .matchedTransitionSource(id: item.id, in: animationID ?? Namespace().wrappedValue)
        .buttonStyle(.plain)
        #endif
    }
}

// TODO: fix teh namespace errors
struct MediaNavigationDestinationModifier: ViewModifier {
    let animation: Namespace.ID
    
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: BaseItemDto.self) { item in
                // TODO: use Group {} for teh transitions
                if item.type == .movie {
                    MovieDetailView(item: item)
#if !os(macOS)
                        .navigationTransition(.zoom(sourceID: item.id, in: animation))
#endif
                } else if item.type == .series || item.type == .episode {
                    let item = BaseItemDto(id: item.seriesID)
                    ShowDetailView(item: item)
#if !os(macOS)
                        .navigationTransition(.zoom(sourceID: item.id, in: animation))
#endif
                }
            }
            .navigationDestination(for: BaseItemPerson.self) { person in
                PersonMediaView(person: person)
            }
            .navigationDestination(for: FilteredMediaViewNavItem.self) { item in
                FilteredMediaView(filter: .library(item.item))
            }
    }
}

extension View {
    public func addNavigationDestionationsForDetailView(animation: Namespace.ID) -> some View {
        modifier(MediaNavigationDestinationModifier(animation: animation))
    }
}
