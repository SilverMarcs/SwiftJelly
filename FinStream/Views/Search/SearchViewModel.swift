//
//  SearchViewModel.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation
import JellyfinAPI

@MainActor
@Observable
final class SearchViewModel {
    private(set) var results: [BaseItemDto] = []
    var isLoading = false

    func results(for scope: SearchScope) -> [BaseItemDto] {
        switch scope {
        case .all: results
        case .movies: results.filter { $0.type == .movie }
        case .shows: results.filter { $0.type == .series }
        case .people: results.filter { $0.type == .person }
        }
    }

    func search(for query: String, source: SearchSource) async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            results = []
            isLoading = false
            return
        }
        isLoading = true

        let effectiveSource = SeerAPI.isConfigured ? source : .jellyfin
        async let jellyfinResults = effectiveSource.includesJellyfin ? jellyfinSearch(trimmedQuery) : []
        async let seerResults = effectiveSource.includesSeer ? seerSearch(trimmedQuery) : []

        let (jellyfin, seer) = await (jellyfinResults, seerResults)
        guard !Task.isCancelled else { return }

        let jellyfinIDs = Set(jellyfin.compactMap(\.id))
        let remainingSeer = seer.filter { result in
            guard let jellyfinMediaID = result.mediaInfo?.jellyfinMediaID else { return true }
            return !jellyfinIDs.contains(jellyfinMediaID)
        }
        let libraryItems = await SeerLibraryResolver.libraryItems(for: remainingSeer.compactMap { $0.mediaInfo?.jellyfinMediaID })
        guard !Task.isCancelled else { return }

        let uniqueSeer = remainingSeer.compactMap { result in
            result.mediaInfo?.jellyfinMediaID.flatMap { libraryItems[$0] } ?? BaseItemDto(seerResult: result)
        }

        results = jellyfin + uniqueSeer
        isLoading = false
    }

    private func jellyfinSearch(_ query: String) async -> [BaseItemDto] {
        do {
            async let content = JFAPI.searchMedia(query: query)
            async let persons = JFAPI.searchPersons(query: query)
            let (contentResults, personResults) = try await (content, persons)
            return contentResults + personResults
        } catch {
            print("Error Searching Jellyfin: \(error.localizedDescription)")
            return []
        }
    }

    private func seerSearch(_ query: String) async -> [SeerSearchResult] {
        do {
            return try await SeerAPI.search(query: query)
        } catch {
            print("Error Searching Seer: \(error.localizedDescription)")
            return []
        }
    }
}
