//
//  SeerMediaRequest.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

struct SeerMediaRequest: Decodable, Hashable, Identifiable {
    let id: Int
    let status: SeerRequestStatus
    let type: SeerMediaType
    let createdAt: String?
    let media: SeerMediaInfo
    let seasons: [SeerRequestedSeason]?
    let requestedBy: SeerUser?

    var reference: SeerMediaReference? {
        media.tmdbID.map { SeerMediaReference(mediaType: type, tmdbID: $0) }
    }

    var displayStatus: SeerRequestDisplayStatus {
        guard type == .tv, status == .approved || status == .completed, let seasons, !seasons.isEmpty else {
            return SeerRequestDisplayStatus(requestStatus: status, mediaStatus: media.status)
        }

        let seasonStatuses = seasons.map { media.status(forSeason: $0.seasonNumber) }
        if seasonStatuses.allSatisfy({ $0 == .available }) {
            return .available
        }
        if seasonStatuses.contains(where: { $0 == .available || $0 == .partiallyAvailable }) {
            return .partiallyAvailable
        }
        return .processing
    }
}

struct SeerRequestedSeason: Decodable, Hashable {
    let seasonNumber: Int
    let status: SeerRequestStatus?
}
