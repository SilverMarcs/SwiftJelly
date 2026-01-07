//
//  MediaNavigationLink.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import JellyfinAPI

struct MediaNavigationLink<Label: View>: View {
    let item: BaseItemDto
    @ViewBuilder let label: () -> Label
    
    var body: some View {
        let navigationItem: any Hashable = {
            switch item.type {
            case .person:
                return Person(from: item)
            case .episode:
                return item.toSeries() ?? item
            default:
                return item
            }
        }()
        
        NavigationLink(value: navigationItem) {
            label()
        }
        .adaptiveButtonStyle()
    }
}

struct MediaNavigationDestinationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: BaseItemDto.self) { item in
                MediaDestinationView(item: item)
            }
            .navigationDestination(for: Person.self) { person in
                FilteredMediaView(filter: .person(id: person.id, name: person.name))
            }
    }
}

extension View {
    public func navigationDestinations() -> some View {
        modifier(MediaNavigationDestinationModifier())
    }
}
