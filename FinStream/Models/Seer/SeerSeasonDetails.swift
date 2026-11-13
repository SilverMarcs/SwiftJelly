//
//  SeerSeasonDetails.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

struct SeerSeasonDetails: Decodable, Hashable {
    let id: Int
    let seasonNumber: Int
    let name: String?
    let episodes: [SeerEpisode]
}

struct SeerEpisode: Decodable, Hashable, Identifiable {
    let id: Int
    let name: String?
    let overview: String?
    let episodeNumber: Int
    let seasonNumber: Int
    let stillPath: String?
    let airDate: String?
    let voteAverage: Double?
}
