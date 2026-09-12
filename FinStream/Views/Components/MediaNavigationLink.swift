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

    #if os(iOS)
    /// The zoom-transition source id, matching the id of the item the
    /// destination will display (the series for episodes). Empty when there is
    /// no zoomable destination.
    private var detailZoomID: String {
        guard let item else { return "" }
        switch item.type {
        case .person:
            return ""
        case .episode:
            return item.toSeries()?.id ?? item.id ?? ""
        default:
            return item.id ?? ""
        }
    }
    #endif
    
    var body: some View {
        // Compute an optional navigation value. When `item` is nil (placeholder),
        // the value is nil, which disables the NavigationLink. Keeping a single
        // NavigationLink of one concrete value type (`NavigationRoute`) for both
        // states preserves the view identity so tvOS focus survives the
        // placeholder → real-item swap.
        let route: NavigationRoute? = {
            guard let item = item else { return nil }
            switch item.type {
            case .person:
                return .person(Person(from: item))
            case .episode:
                return .media(item.toSeries() ?? item)
            default:
                return .media(item)
            }
        }()

        NavigationLink(value: route) {
            label()
        }
        .adaptiveCardButtonStyle()
        #if os(iOS)
        .zoomTransitionSource(id: detailZoomID, in: detailZoomNamespace)
        #endif
    }
}
