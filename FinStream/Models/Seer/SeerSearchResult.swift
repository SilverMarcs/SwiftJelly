//
//  SeerSearchResult.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

struct SeerSearchResult: Decodable, Hashable, Identifiable {
    let id: Int
    let mediaType: String
    let title: String?
    let name: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let mediaInfo: SeerMediaInfo?

    var reference: SeerMediaReference? {
        SeerMediaType(rawValue: mediaType).map { SeerMediaReference(mediaType: $0, tmdbID: id) }
    }

    var displayTitle: String? {
        title ?? name
    }

    var airDate: String? {
        releaseDate ?? firstAirDate
    }
}
