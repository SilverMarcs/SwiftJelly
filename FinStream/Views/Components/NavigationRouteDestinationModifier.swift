//
//  NavigationRouteDestinationModifier.swift
//  FinStream
//

import SwiftUI

/// The destination for every content route.
struct NavigationRouteDestinationView: View {
    let route: NavigationRoute

    var body: some View {
        switch route {
        case .media(let item):
            MediaDestinationView(item: item)
        case .person(let person):
            FilteredMediaView(filter: .person(id: person.id, name: person.name))
        case .filter(let filter):
            FilteredMediaView(filter: filter)
        }
    }
}

extension View {
    /// Registers the content destinations for the enclosing `NavigationStack`.
    ///
    /// Applied directly rather than through a custom `ViewModifier`: SwiftUI
    /// wants `navigationDestination(for:)` on the stack's root view, and burying
    /// it inside a modifier's body has been observed to make pushes resolve to
    /// the wrong level of the stack.
    func navigationRouteDestinations() -> some View {
        navigationDestination(for: NavigationRoute.self) { route in
            NavigationRouteDestinationView(route: route)
        }
    }
}
