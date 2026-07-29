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
        // NavigationLink of one concrete value type (`MediaRoute`) for both states
        // preserves the view identity so tvOS focus survives the placeholder →
        // real-item swap.
        let route: MediaRoute? = {
            guard let item = item else { return nil }
            switch item.type {
            case .person:
                return .person(Person(from: item))
            case .episode:
                return .item(item.toSeries() ?? item)
            default:
                return .item(item)
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

/// A single concrete navigation value used by `MediaNavigationLink` so it can
/// present either an item or a person through one link (and one stable view
/// identity), rather than switching between value types.
enum MediaRoute: Hashable {
    case item(BaseItemDto)
    case person(Person)
}

struct MediaNavigationDestinationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: MediaRoute.self) { route in
                switch route {
                case .item(let item):
                    MediaDestinationView(item: item)
                case .person(let person):
                    FilteredMediaView(filter: .person(id: person.id, name: person.name))
                }
            }
            .navigationDestination(for: BaseItemDto.self) { item in
                MediaDestinationView(item: item)
            }
            .navigationDestination(for: Person.self) { person in
                FilteredMediaView(filter: .person(id: person.id, name: person.name))
            }
            .navigationDestination(for: MediaFilter.self) { filter in
                FilteredMediaView(filter: filter)
            }
    }
}

extension View {
    public func navigationDestinations() -> some View {
        modifier(MediaNavigationDestinationModifier())
    }
}
