//
//  BaseItemDto+Metadata.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 23/10/2025.
//

import AVKit
import JellyfinAPI

extension BaseItemDto {
    /// Creates AVMetadataItems for AVPlayerItem.externalMetadata. The redundancy
    /// across common/quickTime/iTunes identifier spaces is intentional — different
    /// AVKit surfaces (Now Playing strip, Info pane, AirPlay receivers) read
    /// different keys.
    func createMetadataItems() async -> [AVMetadataItem] {
        var metadata: [AVMetadataItem] = []

        // Artwork (fetched first so it's the dominant image in the Info pane).
        if let artworkData = await loadArtwork() {
            metadata.append(makeArtworkItem(artworkData))
        }

        // Title
        let title = metadataTitle
        metadata.append(makeItem(.commonIdentifierTitle, title))
        metadata.append(makeItem(.quickTimeMetadataTitle, title))

        // Subtitle
        if let subtitle = metadataSubtitle {
            metadata.append(makeItem(.iTunesMetadataTrackSubTitle, subtitle))
            metadata.append(makeItem(.commonIdentifierArtist, subtitle))
        }

        // Description (overview, with tagline prepended if available)
        if let description = metadataDescription {
            metadata.append(makeItem(.commonIdentifierDescription, description))
            metadata.append(makeItem(.quickTimeMetadataDescription, description))
            metadata.append(makeItem(.iTunesMetadataDescription, description))
        }

        // Release date / year — movies only; episode air dates are noise.
        if type == .movie {
            if let dateString = metadataReleaseDate {
                metadata.append(makeItem(.commonIdentifierCreationDate, dateString))
                metadata.append(makeItem(.quickTimeMetadataCreationDate, dateString))
            }
            if let year = productionYear {
                metadata.append(makeItem(.iTunesMetadataReleaseDate, String(year)))
            }
        }

        // Genres — joined so multiple show up in the Info row.
        if let genres, !genres.isEmpty {
            let joined = genres.prefix(3).joined(separator: ", ")
            metadata.append(makeItem(.quickTimeMetadataGenre, joined))
            metadata.append(makeItem(.iTunesMetadataUserGenre, joined))
        }

        // Studio → publisher (e.g., HBO, Netflix, A24)
        if let studio = studios?.first?.name {
            metadata.append(makeItem(.commonIdentifierPublisher, studio))
            metadata.append(makeItem(.iTunesMetadataPublisher, studio))
        }

        // Cast — first few people surface in the Info pane / accessibility.
        if let castNames = topCastNames {
            metadata.append(makeItem(.quickTimeMetadataInformation, "Cast: \(castNames)"))
            metadata.append(makeItem(.iTunesMetadataUserComment, castNames))
        }

        // Director — primary creator credit.
        if let director = primaryDirector {
            metadata.append(makeItem(.commonIdentifierCreator, director))
            metadata.append(makeItem(.quickTimeMetadataDirector, director))
        }

        // Content rating (PG-13, R, TV-MA, etc.)
        if let rating = officialRating {
            metadata.append(makeItem(.iTunesMetadataContentRating, rating))
        }

        return metadata
    }

    private var metadataTitle: String {
        name ?? seriesName ?? "Unknown"
    }

    private var metadataSubtitle: String? {
        // No subtitle for movies — year already surfaces via the date row.
        guard type != .movie else { return nil }

        let show = seriesName
        let episodeTag = seasonEpisodeString
        switch (show, episodeTag) {
        case let (show?, episodeTag?): return "\(show) • \(episodeTag)"
        case let (show?, nil): return show
        case let (nil, episodeTag?): return episodeTag
        default: return nil
        }
    }

    private var metadataDescription: String? {
        let tagline = taglines?.first?.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = overview?.trimmingCharacters(in: .whitespacesAndNewlines)
        switch (tagline, body) {
        case let (tagline?, body?) where !tagline.isEmpty && !body.isEmpty && tagline != body:
            return "\(tagline)\n\n\(body)"
        case let (_, body?) where !body.isEmpty:
            return body
        case let (tagline?, _) where !tagline.isEmpty:
            return tagline
        default:
            return nil
        }
    }

    private var metadataReleaseDate: String? {
        if let premiereDate {
            return ISO8601DateFormatter().string(from: premiereDate)
        }
        if let year = productionYear {
            return "\(year)-01-01T00:00:00Z"
        }
        return nil
    }

    private var topCastNames: String? {
        guard let people else { return nil }
        let actors = people.filter { $0.type == .actor }.prefix(4).compactMap { $0.name }
        guard !actors.isEmpty else { return nil }
        return actors.joined(separator: ", ")
    }

    private var primaryDirector: String? {
        people?.first { $0.type == .director }?.name
    }

    private func loadArtwork() async -> Data? {
        guard let url = ImageURLProvider.imageURL(for: self, type: .primary) else {
            return nil
        }
        do {
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
            let (data, _) = try await URLSession.shared.data(for: request)
            return data
        } catch {
            print("Failed to load artwork: \(error)")
            return nil
        }
    }
}

private func makeItem(_ identifier: AVMetadataIdentifier, _ value: String) -> AVMetadataItem {
    let item = AVMutableMetadataItem()
    item.identifier = identifier
    item.value = value as NSString
    item.extendedLanguageTag = "und"
    return item.copy() as! AVMetadataItem
}

private func makeArtworkItem(_ data: Data) -> AVMetadataItem {
    let item = AVMutableMetadataItem()
    item.identifier = .commonIdentifierArtwork
    item.value = data as NSData
    item.extendedLanguageTag = "und"
    return item
}
