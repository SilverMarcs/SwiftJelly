//
//  NavigationRouteDestinationModifier.swift
//  FinStream
//

import SwiftUI

struct NavigationRouteDestinationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.navigationDestination(for: NavigationRoute.self) { route in
            switch route {
            case .media(let item):
                MediaDestinationView(item: item)
            case .person(let person):
                FilteredMediaView(filter: .person(id: person.id, name: person.name))
            }
        }
    }
}

extension View {
    func navigationRouteDestinations() -> some View {
        modifier(NavigationRouteDestinationModifier())
    }
}
