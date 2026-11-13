//
//  SeerDownload.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 13.11.26.
//

import Foundation

/// One download, grouping all per-episode queue entries that share a download ID.
struct SeerDownload: Identifiable, Hashable {
    let id: String
    let title: String
    let state: SeerDownloadState
    let fractionCompleted: Double
    let estimatedCompletion: Date?
    let seasonNumbers: [Int]

    init(id: String, entries: [SeerDownloadStatus]) {
        let first = entries.first

        self.id = id
        self.title = first?.title ?? ""
        self.state = first?.status ?? .unknown
        // Episodes of a season pack all report the size of the whole pack, so one entry is representative.
        self.fractionCompleted = SeerDownload.fraction(size: first?.size, sizeLeft: first?.sizeLeft)
        self.estimatedCompletion = entries.compactMap(\.estimatedCompletion).max()
        self.seasonNumbers = Set(entries.compactMap { $0.episode?.seasonNumber }).sorted()
    }

    static func fraction(size: Double?, sizeLeft: Double?) -> Double {
        guard let size, size > 0 else { return 0 }
        return min(max((size - (sizeLeft ?? size)) / size, 0), 1)
    }
}
