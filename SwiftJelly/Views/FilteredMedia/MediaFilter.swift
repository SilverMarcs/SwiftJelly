//
//  MediaFilter.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 22/09/2025.
//

import Foundation
import JellyfinAPI

enum MediaFilter {
    case library(BaseItemDto)
    case genre(String)
    case studio(NameGuidPair)
    case favorites
    case person(id: String, name: String)
    
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
        }
    }
}
