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
        if let reference = item.seerReference {
            return .seer(reference)
        }
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
        switch route {
        case .media(let destination): destination.id ?? ""
        case .seer(let reference): reference.itemID
        default: ""
        }
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
