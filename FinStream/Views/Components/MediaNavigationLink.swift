//
//  MediaNavigationLink.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import JellyfinAPI

struct MediaNavigationLink<Label: View>: View {
    #if os(iOS)
    @Environment(\.detailZoomNamespace) private var detailZoomNamespace
    #endif

    let item: BaseItemDto?
    @ViewBuilder let label: () -> Label

    private var route: NavigationRoute? {
        guard let item else { return nil }
        switch item.type {
        case .person:
            return .person(Person(from: item))
        case .episode:
            return .media(item.toSeries() ?? item)
        default:
            return .media(item)
        }
    }

    #if os(iOS)
    private var detailZoomID: String {
        guard case .media(let destination) = route else { return "" }
        return destination.id ?? ""
    }
    #endif

    var body: some View {
        // One NavigationLink for placeholder and real item keeps view identity, so tvOS focus survives the swap.
        NavigationLink(value: route) {
            label()
        }
        .adaptiveCardButtonStyle()
        #if os(iOS)
        .zoomTransitionSource(id: detailZoomID, in: detailZoomNamespace)
        #endif
    }
}
