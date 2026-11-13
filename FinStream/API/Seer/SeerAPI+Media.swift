//
//  SeerAPI+Media.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

extension SeerAPI {
    static func movie(id: Int) async throws -> SeerMovieDetails {
        try await send(SeerEndpoint(path: "movie/\(id)"))
    }

    static func tv(id: Int) async throws -> SeerTVDetails {
        try await send(SeerEndpoint(path: "tv/\(id)"))
    }

    static func season(_ seasonNumber: Int, ofShow showID: Int) async throws -> SeerSeasonDetails {
        try await send(SeerEndpoint(path: "tv/\(showID)/season/\(seasonNumber)"))
    }
}
