//
//  SeerDetailViewModel.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation
import JellyfinAPI

@MainActor
@Observable
final class SeerDetailViewModel {
    let reference: SeerMediaReference
    let requestModel: SeerRequestViewModel

    private(set) var item: BaseItemDto
    private(set) var libraryItem: BaseItemDto?
    private(set) var cast: [SeerCreditPerson] = []
    private(set) var seasons: [SeerSeasonSummary] = []
    private(set) var episodes: [ViewListItem<BaseItemDto>] = withPlaceholderItems(size: 8)
    private(set) var errorMessage: String?
    var selectedSeason: SeerSeasonSummary?

    init(reference: SeerMediaReference) {
        self.reference = reference
        self.requestModel = SeerRequestViewModel(reference: reference)
        self.item = BaseItemDto(seerReference: reference)
    }

    func refresh() async {
        do {
            switch reference.mediaType {
            case .movie:
                let movie = try await SeerAPI.movie(id: reference.tmdbID)
                item = BaseItemDto(seerMovie: movie)
                cast = movie.credits?.cast ?? []
                requestModel.apply(mediaInfo: movie.mediaInfo, seasons: [])
            case .tv:
                let show = try await SeerAPI.tv(id: reference.tmdbID)
                item = BaseItemDto(seerShow: show)
                cast = show.credits?.cast ?? []
                seasons = show.regularSeasons
                requestModel.apply(mediaInfo: show.mediaInfo, seasons: seasons)
                if selectedSeason == nil || !seasons.contains(where: { $0.id == selectedSeason?.id }) {
                    selectedSeason = seasons.first
                }
            }
            errorMessage = nil
            libraryItem = await SeerLibraryResolver.libraryItem(for: requestModel.mediaInfo)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadEpisodes() async {
        guard let selectedSeason else { return }
        episodes = withPlaceholderItems(size: min(selectedSeason.episodeCount ?? 8, 8))

        do {
            let season = try await SeerAPI.season(selectedSeason.seasonNumber, ofShow: reference.tmdbID)
            guard selectedSeason == self.selectedSeason else { return }
            episodes = []
            episodes.update(with: season.episodes.map { BaseItemDto(seerEpisode: $0, showName: item.name) })
        } catch {
            episodes = []
            print("Error loading Seer season: \(error)")
        }
    }

    var downloadProgress: SeerDownloadProgress? {
        requestModel.mediaInfo?.downloadProgress
    }

    /// Whether the item is being fetched: either downloads are active or Seer reports it as processing.
    var isProcessing: Bool {
        downloadProgress != nil || requestModel.mediaInfo?.status == .processing
    }

    /// Re-fetches the item periodically while it is processing so download progress stays current.
    func pollWhileProcessing() async {
        while isProcessing, !Task.isCancelled {
            try? await Task.sleep(for: .seconds(15))
            guard !Task.isCancelled else { return }
            await refresh()
        }
    }

    func seasonStatus(for season: SeerSeasonSummary) -> SeerMediaStatus? {
        requestModel.mediaInfo?.status(forSeason: season.seasonNumber)
    }
}
