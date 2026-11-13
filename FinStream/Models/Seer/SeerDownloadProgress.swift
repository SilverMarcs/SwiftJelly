//
//  SeerDownloadProgress.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 13.11.26.
//

import Foundation

/// Aggregated download progress for a Seer media item, mirroring the "Processing" badge on the Seer website.
struct SeerDownloadProgress: Hashable {
    let downloads: [SeerDownload]

    init(statuses: [SeerDownloadStatus]) {
        var order: [String] = []
        var groups: [String: [SeerDownloadStatus]] = [:]

        for (index, status) in statuses.enumerated() {
            let key = status.downloadID ?? status.title ?? "\(index)"
            if groups[key] == nil {
                order.append(key)
            }
            groups[key, default: []].append(status)
        }

        downloads = order.map { SeerDownload(id: $0, entries: groups[$0] ?? []) }
    }

    var isEmpty: Bool { downloads.isEmpty }

    /// Overall progress, averaged across downloads.
    var fractionCompleted: Double {
        guard !downloads.isEmpty else { return 0 }
        return downloads.map(\.fractionCompleted).reduce(0, +) / Double(downloads.count)
    }

    var seasonNumbers: [Int] {
        Set(downloads.flatMap(\.seasonNumbers)).sorted()
    }

    /// Short season label such as "S1" or "S1, S2"; `nil` for movies.
    var seasonLabel: String? {
        let seasons = seasonNumbers
        guard !seasons.isEmpty else { return nil }
        return seasons.map { "S\($0)" }.joined(separator: ", ")
    }

    var title: String {
        if let seasonLabel {
            return String(localized: "Processing \(seasonLabel)")
        }
        return String(localized: "Processing")
    }
}
