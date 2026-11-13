//
//  SeerDownloadStatus.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 13.11.26.
//

import Foundation

/// A single queue entry reported by Seer's download tracker (Sonarr/Radarr queue).
/// Season packs produce one entry per episode, all sharing the same `downloadID`.
struct SeerDownloadStatus: Decodable, Hashable {
    let downloadID: String?
    let title: String?
    let status: SeerDownloadState
    let size: Double?
    let sizeLeft: Double?
    let estimatedCompletionTime: String?
    let episode: SeerDownloadEpisode?

    enum CodingKeys: String, CodingKey {
        case downloadID = "downloadId"
        case title
        case status
        case size
        case sizeLeft
        case estimatedCompletionTime
        case episode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        downloadID = try container.decodeIfPresent(String.self, forKey: .downloadID)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        status = (try? container.decodeIfPresent(SeerDownloadState.self, forKey: .status)) ?? .unknown
        size = try? container.decodeIfPresent(Double.self, forKey: .size)
        sizeLeft = try? container.decodeIfPresent(Double.self, forKey: .sizeLeft)
        estimatedCompletionTime = try? container.decodeIfPresent(String.self, forKey: .estimatedCompletionTime)
        episode = try? container.decodeIfPresent(SeerDownloadEpisode.self, forKey: .episode)
    }

    var estimatedCompletion: Date? {
        guard let estimatedCompletionTime else { return nil }
        return (try? Date(estimatedCompletionTime, strategy: .iso8601.year().month().day().time(includingFractionalSeconds: true)))
            ?? (try? Date(estimatedCompletionTime, strategy: .iso8601))
    }
}
