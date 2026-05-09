//
//  DownloadButton.swift
//  SwiftJelly
//

import SwiftUI
import JellyfinAPI

struct DownloadButton: View {
    let item: BaseItemDto
    @State private var manager = DownloadManager.shared

    private var record: DownloadRecord? {
        manager.record(for: item.id)
    }

    var body: some View {
        Group {
            switch record?.status {
            case .downloading:
                Menu {
                    Button(role: .destructive) {
                        if let id = item.id { manager.cancelDownload(for: id) }
                    } label: {
                        Label("Cancel Download", systemImage: "xmark")
                    }
                } label: {
                    downloadingLabel
                }

            case .completed:
                Menu {
                    Button(role: .destructive) {
                        if let id = item.id { manager.deleteDownload(for: id) }
                    } label: {
                        Label("Remove Download", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "arrow.down")
                }
                .tint(.green)

            case .failed:
                Button {
                    manager.startDownload(for: item)
                } label: {
                    Image(systemName: "exclamationmark.triangle")
                }
                .tint(.orange)

            case .none:
                Button {
                    manager.startDownload(for: item)
                } label: {
                    Image(systemName: "arrow.down")
                }
            }
        }
        .animation(.snappy, value: record?.status)
    }

    @ViewBuilder
    private var downloadingLabel: some View {
        // Jellyfin's stream endpoint doesn't report Content-Length when remuxing
        // or transcoding, so a determinate progress ring would always sit at 0%.
        // Use an indeterminate spinner instead.
        ProgressView()
    }
}
