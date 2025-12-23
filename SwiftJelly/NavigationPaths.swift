//
//  NavigationPaths.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 06.12.25.
//

import SwiftUI
import JellyfinAPI

struct NavigationPaths: ViewModifier {
    var animation: Namespace.ID
    
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: BaseItemDto.self) { item in
                if item.type == .movie {
                    MovieDetailView(item: item)
#if !os(macOS)
                        .navigationTransition(.zoom(sourceID: item.id, in: animation))
#endif
                } else if item.type == .series {
                    ShowDetailView(item: item)
#if !os(macOS)
                        .navigationTransition(.zoom(sourceID: item.id, in: animation))
#endif
                }
            }
        
            .navigationDestination(for: FilteredMediaViewNavItem.self) { item in
                FilteredMediaView(filter: .library(item.item))
            }

            .navigationDestination(for: BaseItemPerson.self) { person in
                PersonMediaView(person: person)
            }

            .navigationDestination(for: ShowDetailLoaderNavigationItem.self) { detail in
                ShowDetailLoader(episode: detail.episode)
                    .navigationTitle("")
            }

            .navigationDestination(for: ServerListNavigationItem.self) { _ in
                ServerList()
            }
    }
}

struct ShowDetailLoaderNavigationItem: Hashable {
    public let episode: BaseItemDto
}

struct ServerListNavigationItem: Hashable {}

extension View {
    public func addNavigationTargets(animation: Namespace.ID) -> some View {
        modifier(NavigationPaths(animation: animation))
    }
}
