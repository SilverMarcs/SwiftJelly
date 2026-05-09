//
//  DownloadsView.swift
//  SwiftJelly
//

import SwiftUI
import JellyfinAPI

struct DownloadsView: View {
    @State private var manager = DownloadManager.shared

    /// Either a single record (movie / one-off) or a series aggregating its
    /// episode records.
    private enum Entry: Identifiable {
        case single(DownloadRecord)
        case series(seriesID: String, seriesName: String, records: [DownloadRecord])

        var id: String {
            switch self {
            case .single(let r): return "single-\(r.id)"
            case .series(let id, _, _): return "series-\(id)"
            }
        }

        /// Considered "downloading" for section placement if any underlying
        /// record is not yet completed (i.e. still downloading or failed).
        var isAllCompleted: Bool {
            switch self {
            case .single(let r): return r.status == .completed
            case .series(_, _, let rs): return rs.allSatisfy { $0.status == .completed }
            }
        }

        /// Latest activity for sort ordering.
        var dateAdded: Date {
            switch self {
            case .single(let r): return r.dateAdded
            case .series(_, _, let rs): return rs.map(\.dateAdded).max() ?? .distantPast
            }
        }
    }

    private var entries: [Entry] {
        let records = manager.sortedRecords()

        var seriesBuckets: [String: [DownloadRecord]] = [:]
        var singles: [DownloadRecord] = []
        for record in records {
            if record.item.type == .episode, let seriesID = record.item.seriesID {
                seriesBuckets[seriesID, default: []].append(record)
            } else {
                singles.append(record)
            }
        }

        var result: [Entry] = singles.map { .single($0) }
        for (seriesID, recs) in seriesBuckets {
            let name = recs.first?.item.seriesName ?? "Unknown Show"
            result.append(.series(seriesID: seriesID, seriesName: name, records: recs))
        }
        return result.sorted { $0.dateAdded > $1.dateAdded }
    }

    var body: some View {
        let entries = entries
        let downloading = entries.filter { !$0.isAllCompleted }
        let completed = entries.filter { $0.isAllCompleted }

        List {
            if !downloading.isEmpty {
                Section("Downloading") {
                    ForEach(downloading) { entry in
                        row(for: entry)
                    }
                }
            }

            if !completed.isEmpty {
                Section("Downloaded") {
                    ForEach(completed) { entry in
                        row(for: entry)
                    }
                }
            }
        }
        .overlay {
            if manager.downloads.isEmpty {
                ContentUnavailableView(
                    "No Downloads",
                    systemImage: "arrow.down.to.line",
                    description: Text("Downloaded items will appear here for offline playback.")
                )
            }
        }
        .navigationTitle("Downloads")
        .platformNavigationToolbar(titleDisplayMode: .inline)
        .keepScreenAwakeWhile(hasActiveDownloads)
    }

    private var hasActiveDownloads: Bool {
        manager.downloads.values.contains { $0.status == .downloading }
    }

    @ViewBuilder
    private func row(for entry: Entry) -> some View {
        switch entry {
        case .single(let record):
            DownloadRow(record: record)
        case .series(let seriesID, let seriesName, let records):
            SeriesDownloadRow(
                seriesID: seriesID,
                seriesName: seriesName,
                episodeRecords: records
            )
        }
    }
}
