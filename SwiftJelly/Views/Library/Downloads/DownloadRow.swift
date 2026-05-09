//
//  DownloadRow.swift
//  SwiftJelly
//

import SwiftUI
import JellyfinAPI

struct DownloadRow: View {
    let record: DownloadRecord
    /// When false, the series name is omitted from the subtitle — used inside
    /// `SeriesDownloadsView` where the show is already the navigation title.
    var showsSeriesName: Bool = true
    @State private var manager = DownloadManager.shared

    private var isDownloading: Bool { record.status == .downloading }

    var body: some View {
        HStack {
            PlayMediaButton(item: record.item) {
                DownloadCellContent(
                    item: record.item,
                    title: record.item.name ?? "Unknown",
                    subtitle: subtitle
                )
            }
            .buttonStyle(.plain)
            .allowsHitTesting(!isDownloading)

            accessory
        }
        #if !os(tvOS)
        .swipeActions {
            Button(role: .destructive, action: removeAction) {
                Label(
                    isDownloading ? "Cancel" : "Delete",
                    systemImage: isDownloading ? "xmark" : "trash"
                )
            }
        }
        #endif
    }

    @ViewBuilder
    private var accessory: some View {
        Menu {
            Button(role: .destructive, action: removeAction) {
                Label(
                    isDownloading ? "Cancel Download" : "Delete Download",
                    systemImage: isDownloading ? "xmark" : "trash"
                )
            }
        } label: {
            switch record.status {
            case .downloading:
                // Jellyfin's remux/transcode endpoint streams without a known
                // Content-Length, so a determinate progress ring would always
                // sit at 0%. Show a stop affordance instead.
                Image(systemName: "stop.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.tint)
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
            }
        }
        .buttonStyle(.plain)
    }

    private func removeAction() {
        if isDownloading {
            manager.cancelDownload(for: record.id)
        } else {
            manager.deleteDownload(for: record.id)
        }
    }

    private var subtitle: String {
        let item = record.item
        var parts: [String] = []

        if let seasonEpisode = item.seasonEpisodeString {
            parts.append(seasonEpisode)
        }
        if showsSeriesName, let series = item.seriesName {
            parts.append(series)
        } else if item.seriesName == nil, let year = item.productionYear {
            parts.append(String(year))
        }

        switch record.status {
        case .downloading:
            // Read live progress from the manager so the row updates as bytes
            // arrive — `record` is a struct snapshot from when the row was built.
            let live = manager.downloads[record.id] ?? record
            let written = live.bytesWritten
            let total = live.totalBytes
            let writtenStr = ByteCountFormatter.string(fromByteCount: written, countStyle: .file)
            if total > 0 {
                let totalStr = ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
                let pct = Int((Double(written) / Double(total)) * 100)
                parts.append("Downloading · \(writtenStr) / \(totalStr) · \(pct)%")
            } else if written > 0 {
                parts.append("Downloading · \(writtenStr)")
            } else {
                parts.append("Downloading…")
            }
        case .completed:
            if record.totalBytes > 0 {
                parts.append(ByteCountFormatter.string(fromByteCount: record.totalBytes, countStyle: .file))
            }
        case .failed:
            parts.append("Failed")
        }

        return parts.joined(separator: " \u{00B7} ")
    }
}
