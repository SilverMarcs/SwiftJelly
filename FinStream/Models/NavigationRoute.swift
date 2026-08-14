//
//  NavigationRoute.swift
//  FinStream
//

import JellyfinAPI

/// A concrete route shared by every content navigation link in the app.
///
/// Keeping the payload behind one concrete type lets SwiftUI reliably match
/// links to their destination on every platform. Equality and hashing use
/// stable server identifiers instead of every mutable field in a Jellyfin DTO.
enum NavigationRoute: Hashable {
    case media(BaseItemDto)
    case person(Person)

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.media(lhsItem), .media(rhsItem)):
            if let lhsID = lhsItem.id, let rhsID = rhsItem.id {
                return lhsID == rhsID && lhsItem.type == rhsItem.type
            }
            return lhsItem == rhsItem
        case let (.person(lhsPerson), .person(rhsPerson)):
            return lhsPerson.id == rhsPerson.id && lhsPerson.name == rhsPerson.name
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .media(let item):
            hasher.combine(0)
            if let id = item.id {
                hasher.combine(id)
                hasher.combine(item.type)
            } else {
                hasher.combine(item)
            }
        case .person(let person):
            hasher.combine(1)
            hasher.combine(person.id)
            hasher.combine(person.name)
        }
    }
}
