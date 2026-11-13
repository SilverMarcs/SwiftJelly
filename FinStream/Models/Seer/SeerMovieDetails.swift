//
//  SeerMovieDetails.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

struct SeerMovieDetails: Decodable, Hashable {
    let id: Int
    let title: String
    let overview: String?
    let tagline: String?
    let runtime: Int?
    let releaseDate: String?
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double?
    let genres: [SeerNamedEntity]?
    let credits: SeerCredits?
    let productionCompanies: [SeerNamedEntity]?
    let productionCountries: [SeerNamedEntity]?
    let releases: SeerReleases?
    let mediaInfo: SeerMediaInfo?

    var reference: SeerMediaReference {
        SeerMediaReference(mediaType: .movie, tmdbID: id)
    }
}
