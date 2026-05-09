//
//  DownloadsLibraryCard.swift
//  SwiftJelly
//

import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct DownloadsLibraryCard: View {
    @State private var manager = DownloadManager.shared

    var body: some View {
        ZStack {
            background

            VStack(spacing: 6) {
                Image(systemName: "arrow.down.to.line")
                    .font(.largeTitle)
                Text("Downloads")
                    .font(.title)
                    .bold()
                Text(subtitle)
                    .font(.caption)
            }
            .foregroundStyle(hasItems ? Color.white : Color.secondary)
            .shadow(color: hasItems ? .black.opacity(0.6) : .clear, radius: 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(.background.secondary)
    }

    private var hasItems: Bool { !backdropURLs.isEmpty }

    @ViewBuilder
    private var background: some View {
        if hasItems {
            backdropGrid
                .overlay(Color.black.opacity(0.55))
        }
    }

    @ViewBuilder
    private var backdropGrid: some View {
        // Up to four tiles; pad with nil so the grid stays 2x2 even if we have
        // fewer items.
        let tiles = Array(backdropURLs.prefix(4))
        let padded: [URL?] = tiles.map(Optional.some) + Array(repeating: nil, count: max(0, 4 - tiles.count))

        VStack(spacing: 0) {
            HStack(spacing: 0) {
                tile(padded[0])
                tile(padded[1])
            }
            HStack(spacing: 0) {
                tile(padded[2])
                tile(padded[3])
            }
        }
    }

    @ViewBuilder
    private func tile(_ url: URL?) -> some View {
        if let url {
            CachedAsyncImage(url: url, targetSize: 400) {
                Color.clear
            }
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        } else {
            Color.black.opacity(0.2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// One backdrop URL per *show* (episodes collapsed by series) or per movie,
    /// shuffled. Episodes use the show's backdrop, not the episode thumbnail.
    private var backdropURLs: [URL] {
        var seenSeries = Set<String>()
        var urls: [URL] = []
        for record in manager.downloads.values {
            let item = record.item
            if item.type == .episode, let seriesID = item.seriesID {
                if !seenSeries.insert(seriesID).inserted { continue }
            }
            if let url = ImageURLProvider.bestBackdropURL(for: item) {
                urls.append(url)
            }
        }
        // Stable random order keyed off the set of IDs so it doesn't reshuffle
        // on every redraw.
        var rng = SystemRandomNumberGeneratorWithSeed(seed: UInt64(urls.count))
        urls.shuffle(using: &rng)
        return urls
    }

    private var subtitle: String {
        let count = manager.downloads.count
        if count == 0 { return "Saved for offline" }
        return "\(count) item\(count == 1 ? "" : "s")"
    }
}

/// Tiny seeded RNG used to keep the random tile order stable across redraws
/// for the same set of downloads. Not cryptographically meaningful.
private struct SystemRandomNumberGeneratorWithSeed: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { self.state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z &>> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z &>> 27)) &* 0x94D049BB133111EB
        return z ^ (z &>> 31)
    }
}
