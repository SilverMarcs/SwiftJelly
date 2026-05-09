//
//  SeriesDownloadRow.swift
//  SwiftJelly
//

import SwiftUI
import JellyfinAPI

/// Row representing a TV show in the downloads list. Aggregates one or more
/// episode `DownloadRecord`s and links to a detail page that lists each
/// episode using the standard `DownloadRow`.
struct SeriesDownloadRow: View {
    let seriesID: String
    let seriesName: String
    let episodeRecords: [DownloadRecord]
    @State private var manager = DownloadManager.shared

    private var anyDownloading: Bool {
        liveRecords.contains { $0.status == .downloading }
    }

    private var liveRecords: [DownloadRecord] {
        episodeRecords.compactMap { manager.downloads[$0.id] }
    }

    /// Episode used purely as a metadata source (poster, series name) for the
    /// row layout. Any of the records works; we take the first.
    private var representativeEpisode: BaseItemDto? {
        episodeRecords.first?.item
    }

    var body: some View {
        NavigationLink {
            SeriesDownloadsView(seriesID: seriesID, seriesName: seriesName)
        } label: {
            HStack {
                DownloadCellContent(
                    item: representativeEpisode,
                    imageURLOverride: representativeEpisode.flatMap { ImageURLProvider.seriesImageURL(for: $0) },
                    title: seriesName,
                    subtitle: subtitle
                )
                accessory
            }
        }
        .buttonStyle(.plain)
        #if !os(tvOS)
        .swipeActions {
            Button(role: .destructive, action: removeAll) {
                Label(
                    anyDownloading ? "Cancel" : "Delete",
                    systemImage: anyDownloading ? "xmark" : "trash"
                )
            }
        }
        #endif
    }

    @ViewBuilder
    private var accessory: some View {
        if anyDownloading {
            ProgressView()
                // .controlSize(.small)
        }
    }

    private var subtitle: String {
        let live = liveRecords.isEmpty ? episodeRecords : liveRecords
        let total = live.count
        let completed = live.filter { $0.status == .completed }.count
        let bytes = live.reduce(into: Int64(0)) { partial, r in
            partial += (r.status == .completed ? r.totalBytes : r.bytesWritten)
        }
        var parts: [String] = []
        if anyDownloading {
            parts.append("\(completed) of \(total) downloaded")
        } else {
            parts.append(total == 1 ? "1 episode" : "\(total) episodes")
        }
        if bytes > 0 {
            parts.append(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))
        }
        return parts.joined(separator: " \u{00B7} ")
    }

    private func removeAll() {
        for record in liveRecords {
            if record.status == .downloading {
                manager.cancelDownload(for: record.id)
            } else {
                manager.deleteDownload(for: record.id)
            }
        }
    }
}
