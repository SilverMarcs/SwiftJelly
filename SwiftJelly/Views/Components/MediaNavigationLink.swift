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
    
    var body: some View {
        Group {
            if item.type == .boxSet {
                NavigationLink(value: FilteredMediaViewNavItem(item: item)) {
                    MediaCard(item: item)
                }
                #if os(tvOS)
                .buttonStyle(.borderless)
                #else
                .buttonStyle(.plain)
                #endif
                .optionalMatchedTransitionSource(id: item.id, in: animationID)
            } else {
                NavigationLink(value: item) {
                    MediaCard(item: item)
                }
                .optionalMatchedTransitionSource(id: item.id, in: animationID)
                #if os(tvOS)
                .buttonStyle(.borderless)
                #else
                .buttonStyle(.plain)
                #endif
            }
        }
    }
}
