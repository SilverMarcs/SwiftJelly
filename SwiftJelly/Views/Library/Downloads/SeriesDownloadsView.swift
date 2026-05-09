//
//  SeriesDownloadsView.swift
//  SwiftJelly
//

import SwiftUI
import JellyfinAPI

/// Detail page listing every downloaded (or in-progress) episode of a series,
/// grouped by season. Each row reuses `DownloadRow` so playback / cancel /
/// delete behaviour matches the main downloads page.
struct SeriesDownloadsView: View {
    let seriesID: String
    let seriesName: String
    @State private var manager = DownloadManager.shared

    private var seasonGroups: [(season: Int, records: [DownloadRecord])] {
        let records = manager.sortedRecords()
            .filter { $0.item.seriesID == seriesID && $0.item.type == .episode }
        let grouped = Dictionary(grouping: records) { $0.item.parentIndexNumber ?? 0 }
        return grouped
            .map { (season: $0.key, records: $0.value.sorted { ($0.item.indexNumber ?? 0) < ($1.item.indexNumber ?? 0) }) }
            .sorted { $0.season < $1.season }
    }

    var body: some View {
        List {
            ForEach(seasonGroups, id: \.season) { group in
                Section(sectionTitle(for: group.season)) {
                    ForEach(group.records) { record in
                        DownloadRow(record: record, showsSeriesName: false)
                    }
                }
            }
        }
        .overlay {
            if seasonGroups.isEmpty {
                ContentUnavailableView(
                    "No Episodes",
                    systemImage: "tv",
                    description: Text("Episodes downloaded for this show will appear here.")
                )
            }
        }
        .navigationTitle(seriesName)
        .platformNavigationToolbar(titleDisplayMode: .inline)
        .keepScreenAwakeWhile(hasActiveSeriesDownloads)
    }

    private var hasActiveSeriesDownloads: Bool {
        seasonGroups.contains { $0.records.contains { $0.status == .downloading } }
    }

    private func sectionTitle(for season: Int) -> String {
        season > 0 ? "Season \(season)" : "Specials"
    }
}
