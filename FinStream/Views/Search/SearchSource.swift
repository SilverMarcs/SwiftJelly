//
//  SearchSource.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

enum SearchSource: String, CaseIterable, Identifiable {
    case all
    case jellyfin
    case seer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "Jellyfin & Seer"
        case .jellyfin: "Jellyfin"
        case .seer: "Seer"
        }
    }

    var systemImage: String {
        switch self {
        case .all: "square.stack"
        case .jellyfin: "server.rack"
        case .seer: "sparkle.magnifyingglass"
        }
    }

    var includesJellyfin: Bool { self != .seer }
    var includesSeer: Bool { self != .jellyfin }
}
