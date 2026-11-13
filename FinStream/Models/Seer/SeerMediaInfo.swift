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
    let downloadStatus: [SeerDownloadStatus]?
    let downloadStatus4k: [SeerDownloadStatus]?

    enum CodingKeys: String, CodingKey {
        case tmdbID = "tmdbId"
        case mediaType
        case status
        case jellyfinMediaID = "jellyfinMediaId"
        case seasons
        case downloadStatus
        case downloadStatus4k
    }

    /// Active downloads (regular and 4K), or `nil` if nothing is downloading.
    var downloadProgress: SeerDownloadProgress? {
        let progress = SeerDownloadProgress(statuses: (downloadStatus ?? []) + (downloadStatus4k ?? []))
        return progress.isEmpty ? nil : progress
    }

    func status(forSeason seasonNumber: Int) -> SeerMediaStatus? {
        seasons?.first { $0.seasonNumber == seasonNumber }?.status
    }
}

struct SeerSeasonStatus: Decodable, Hashable {
    let seasonNumber: Int
    let status: SeerMediaStatus
}
