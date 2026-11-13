//
//  SeerLibraryProgressViewModel.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 13.11.26.
//

import Foundation
import JellyfinAPI

/// Loads Seer download progress for an item that already exists in the Jellyfin library
/// (e.g. a partially available show with a season still downloading).
@MainActor
@Observable
final class SeerLibraryProgressViewModel {
    private(set) var downloadProgress: SeerDownloadProgress?
    private var reference: SeerMediaReference?
    private var loadedItemID: String?

    func load(for item: BaseItemDto) async {
        guard SeerAPI.isConfigured, let itemID = item.id else { return }

        if loadedItemID != itemID {
            let mediaType: SeerMediaType
            switch item.type {
            case .series: mediaType = .tv
            case .movie: mediaType = .movie
            default: return
            }
            guard let tmdbID = await SeerLibraryResolver.tmdbID(for: item) else { return }
            reference = SeerMediaReference(mediaType: mediaType, tmdbID: tmdbID)
            loadedItemID = itemID
        }

        await refresh()
    }

    /// Keeps progress current while something is downloading.
    func pollWhileDownloading() async {
        while downloadProgress != nil, !Task.isCancelled {
            try? await Task.sleep(for: .seconds(15))
            guard !Task.isCancelled else { return }
            await refresh()
        }
    }

    private func refresh() async {
        guard let reference else { return }
        do {
            let mediaInfo: SeerMediaInfo? = switch reference.mediaType {
            case .movie: try await SeerAPI.movie(id: reference.tmdbID).mediaInfo
            case .tv: try await SeerAPI.tv(id: reference.tmdbID).mediaInfo
            }
            downloadProgress = mediaInfo?.downloadProgress
        } catch {
            print("Error loading Seer download progress: \(error)")
        }
    }
}
