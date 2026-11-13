//
//  SeerSeasonSummary.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

struct SeerSeasonSummary: Decodable, Hashable, Identifiable {
    let id: Int
    let seasonNumber: Int
    let name: String?
    let episodeCount: Int?
    let airDate: String?
    let posterPath: String?

    var displayName: String {
        name ?? "Season \(seasonNumber)"
    }
}
