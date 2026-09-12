//
//  MediaFilter.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 22/09/2025.
//

import Foundation
import JellyfinAPI

enum MediaFilter: Hashable {
    case library(BaseItemDto)
    case genre(String)
    case studio(NameGuidPair)
    case favorites
    case person(id: String, name: String)
    case recentlyAdded(BaseItemKind)

    var navigationTitle: String {
        switch self {
        case .library(let library):
            return library.name ?? "Library"
        case .genre(let genre):
            return genre.capitalized
        case .studio(let studio):
            return studio.name ?? "Studio"
        case .favorites:
            return "Favorites"
        case .person(_, let name):
            return name
        case .recentlyAdded(let kind):
            switch kind {
            case .movie: return "Recently Added Movies"
            case .series: return "Recently Added Shows"
            default: return "Recently Added"
            }
        }
    }

    /// Stable identity used for `Hashable`.
    ///
    /// Jellyfin DTOs carry mutable user data (played state, favourite flag,
    /// playback position) that changes while a filter view is on screen. Hashing
    /// the whole DTO would make a pushed navigation value stop matching itself
    /// and the stack would drop the screen, so only stable identifiers count.
    private var identity: String {
        switch self {
        case .library(let library):
            return "library:\(library.id ?? "")|\(library.collectionType?.rawValue ?? "")|\(library.name ?? "")"
        case .genre(let genre):
            return "genre:\(genre)"
        case .studio(let studio):
            return "studio:\(studio.id ?? studio.name ?? "")"
        case .favorites:
            return "favorites"
        case .person(let id, let name):
            return "person:\(id)|\(name)"
        case .recentlyAdded(let kind):
            return "recentlyAdded:\(kind.rawValue)"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identity == rhs.identity
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(identity)
    }
}
