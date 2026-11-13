//
//  SeerMediaReference.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

struct SeerMediaReference: Hashable, Codable {
    static let serverID = "seer"

    let mediaType: SeerMediaType
    let tmdbID: Int

    var itemID: String {
        "\(Self.serverID)-\(mediaType.rawValue)-\(tmdbID)"
    }

    init(mediaType: SeerMediaType, tmdbID: Int) {
        self.mediaType = mediaType
        self.tmdbID = tmdbID
    }

    init?(itemID: String) {
        let components = itemID.split(separator: "-")
        guard components.count == 3,
              components[0] == Self.serverID,
              let mediaType = SeerMediaType(rawValue: String(components[1])),
              let tmdbID = Int(components[2]) else {
            return nil
        }
        self.init(mediaType: mediaType, tmdbID: tmdbID)
    }
}

enum SeerMediaType: String, Codable, Hashable {
    case movie
    case tv
}
