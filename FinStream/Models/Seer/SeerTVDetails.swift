//
//  SeerTVDetails.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

struct SeerTVDetails: Decodable, Hashable {
    let id: Int
    let name: String
    let overview: String?
    let tagline: String?
    let status: String?
    let firstAirDate: String?
    let lastAirDate: String?
    let episodeRunTime: [Int]?
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double?
    let genres: [SeerNamedEntity]?
    let credits: SeerCredits?
    let networks: [SeerNamedEntity]?
    let productionCountries: [SeerNamedEntity]?
    let contentRatings: SeerContentRatings?
    let seasons: [SeerSeasonSummary]?
    let mediaInfo: SeerMediaInfo?

    var reference: SeerMediaReference {
        SeerMediaReference(mediaType: .tv, tmdbID: id)
    }

    var regularSeasons: [SeerSeasonSummary] {
        (seasons ?? []).filter { $0.seasonNumber > 0 }
    }
}
