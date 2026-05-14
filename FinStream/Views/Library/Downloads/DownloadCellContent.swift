//
//  DownloadCellContent.swift
//  SwiftJelly
//

import SwiftUI
import JellyfinAPI

/// Shared visual layout for download list rows: poster on the left, title and
/// subtitle stacked. Used by both the per-record `DownloadRow` and the
/// per-series `SeriesDownloadRow`, and re-used inside `SeriesDownloadsView`.
struct DownloadCellContent: View {
    let item: BaseItemDto?
    var imageURLOverride: URL? = nil
    let title: String
    let subtitle: String

    var body: some View {
        HStack {
            LandscapeImageView(item: item, imageURLOverride: imageURLOverride) {
                Image(systemName: "film")
                    .foregroundStyle(.secondary)
            }
            .aspectRatio(16/9, contentMode: .fill)
            .frame(width: 100)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
    }
}
