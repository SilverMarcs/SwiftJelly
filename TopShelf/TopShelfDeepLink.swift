//
//  TopShelfDeepLink.swift
//  TopShelf
//
//  Created by Zabir Raihan on 07/01/2026.
//

import Foundation

enum TopShelfDeepLinkAction: String {
    case play
    case open
}

struct TopShelfDeepLink {
    static let scheme = "swiftjelly"

    static func makeURL(action: TopShelfDeepLinkAction, itemID: String) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = action.rawValue
        components.path = "/\(itemID)"
        return components.url
    }
}
