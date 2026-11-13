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
        SeerRequestDisplayStatus(requestStatus: status, mediaStatus: media.status)
    }
}

struct SeerRequestedSeason: Decodable, Hashable {
    let seasonNumber: Int
    let status: SeerRequestStatus?
}
