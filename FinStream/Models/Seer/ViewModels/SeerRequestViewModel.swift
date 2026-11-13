//
//  SeerRequestViewModel.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation
import JellyfinAPI

@MainActor
@Observable
final class SeerRequestViewModel {
    let reference: SeerMediaReference

    private(set) var mediaInfo: SeerMediaInfo?
    private(set) var seasons: [SeerSeasonSummary] = []
    private(set) var hasLoaded = false
    private(set) var isRequesting = false
    var isSelectingSeasons = false
    var errorMessage: String?

    init(reference: SeerMediaReference) {
        self.reference = reference
    }

    var state: SeerRequestState {
        hasLoaded ? SeerRequestState(status: mediaInfo?.status) : .loading
    }

    var libraryItem: BaseItemDto? {
        guard let jellyfinMediaID = mediaInfo?.jellyfinMediaID, !jellyfinMediaID.isEmpty else { return nil }
        return BaseItemDto(id: jellyfinMediaID, type: reference.mediaType == .movie ? .movie : .series)
    }

    var requestableSeasons: [SeerSeasonSummary] {
        seasons.filter { SeerRequestState(status: mediaInfo?.status(forSeason: $0.seasonNumber)) == .requestable }
    }

    func apply(mediaInfo: SeerMediaInfo?, seasons: [SeerSeasonSummary]) {
        self.mediaInfo = mediaInfo
        self.seasons = seasons
        hasLoaded = true
    }

    func load() async {
        do {
            switch reference.mediaType {
            case .movie:
                let movie = try await SeerAPI.movie(id: reference.tmdbID)
                apply(mediaInfo: movie.mediaInfo, seasons: [])
            case .tv:
                let show = try await SeerAPI.tv(id: reference.tmdbID)
                apply(mediaInfo: show.mediaInfo, seasons: show.regularSeasons)
            }
        } catch {
            print("Error loading Seer request state: \(error)")
        }
    }

    func beginRequest() async {
        switch reference.mediaType {
        case .movie:
            await submit(seasons: nil)
        case .tv:
            isSelectingSeasons = true
        }
    }

    func submit(seasons: [Int]?) async {
        guard !isRequesting else { return }
        isRequesting = true
        defer { isRequesting = false }

        do {
            try await SeerAPI.request(reference, seasons: seasons)
            isSelectingSeasons = false
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
