//
//  Person.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 14/12/2025.
//

import Foundation
import JellyfinAPI

struct Person: Hashable, Identifiable {
    let id: String
    let name: String
    let subtitle: String?
}

// MARK: - Convenience Initializers
extension Person {
    /// Initialize from BaseItemPerson (cast/crew lists)
    init(from person: BaseItemPerson) {
        self.id = person.id ?? ""
        self.name = person.name ?? "Unknown"
        self.subtitle = person.role
    }
    
    /// Initialize from BaseItemDto (person search results)
    init(from item: BaseItemDto) {
        self.id = item.id ?? ""
        self.name = item.name ?? "Unknown"
        self.subtitle = nil
    }
}
