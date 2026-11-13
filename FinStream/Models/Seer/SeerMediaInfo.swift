//
//  SeerMediaInfo.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

struct SeerMediaInfo: Decodable, Hashable {
    let tmdbID: Int?
    let mediaType: SeerMediaType?
    let status: SeerMediaStatus?
    let jellyfinMediaID: String?
    let seasons: [SeerSeasonStatus]?

    enum CodingKeys: String, CodingKey {
        case tmdbID = "tmdbId"
        case mediaType
        case status
        case jellyfinMediaID = "jellyfinMediaId"
        case seasons
    }

    func status(forSeason seasonNumber: Int) -> SeerMediaStatus? {
        seasons?.first { $0.seasonNumber == seasonNumber }?.status
    }
}

struct SeerSeasonStatus: Decodable, Hashable {
    let seasonNumber: Int
    let status: SeerMediaStatus
}
