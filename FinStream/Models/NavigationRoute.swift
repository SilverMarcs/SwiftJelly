//
//  NavigationRoute.swift
//  FinStream
//

import JellyfinAPI

/// A concrete route shared by every content navigation link in the app.
///
/// Every push inside the content stacks must go through this type. Mixing
/// value-based links (`NavigationLink(value:)`) with view-based links
/// (`NavigationLink { destination }`) in the same `NavigationStack` makes
/// SwiftUI resolve the top of the stack incorrectly: the pushed screen appears
/// for a frame, then the view-based screen is shown again with the real
/// destination stranded one level down.
///
/// Equality and hashing use stable server identifiers instead of every mutable
/// field in a Jellyfin DTO, so a pushed route keeps matching itself while user
/// data (played/favourite/progress) refreshes underneath it.
enum NavigationRoute: Hashable {
    case media(BaseItemDto)
    case person(Person)
    case filter(MediaFilter)

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.media(lhsItem), .media(rhsItem)):
            if let lhsID = lhsItem.id, let rhsID = rhsItem.id {
                return lhsID == rhsID && lhsItem.type == rhsItem.type
            }
            return lhsItem == rhsItem
        case let (.person(lhsPerson), .person(rhsPerson)):
            return lhsPerson.id == rhsPerson.id && lhsPerson.name == rhsPerson.name
        case let (.filter(lhsFilter), .filter(rhsFilter)):
            return lhsFilter == rhsFilter
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
        case .filter(let filter):
            hasher.combine(2)
            hasher.combine(filter)
        }
    }
}
