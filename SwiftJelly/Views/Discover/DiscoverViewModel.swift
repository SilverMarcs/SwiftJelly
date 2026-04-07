//
//  DiscoverViewModel.swift
//  SwiftJelly
//

import SwiftUI

@Observable
final class DiscoverViewModel {
    enum MediaType: String, CaseIterable {
        case movies = "Movies"
        case shows = "Shows"
    }

    var selectedType: MediaType = .movies
    var filters = DiscoverFilters()
    var results: [SeerrSearchResult] = []
    var isLoading = false
    var currentPage = 1
    var totalPages = 1

    private var lastLoadedType: MediaType?
    private var lastLoadedFilters: DiscoverFilters?

    var serverURL: URL? {
        guard let urlString = UserDefaults.standard.string(forKey: "seerrServerURL"),
              let url = URL(string: urlString) else { return nil }
        return url
    }

    var needsReload: Bool {
        results.isEmpty || lastLoadedType != selectedType || lastLoadedFilters != filters
    }

    func loadIfNeeded() async {
        if needsReload {
            await reload()
        }
    }

    func reload() async {
        guard let serverURL else { return }
        guard !isLoading else { return }

        isLoading = true
        currentPage = 1
        lastLoadedType = selectedType
        lastLoadedFilters = filters

        do {
            let response = try await fetchPage(serverURL: serverURL, page: 1)
            withAnimation {
                results = response.results
            }
            totalPages = response.totalPages
        } catch {
            print("Discover error: \(error)")
        }

        isLoading = false
    }

    func loadMore() async {
        guard let serverURL else { return }
        guard !isLoading else { return }
        guard currentPage < totalPages else { return }

        isLoading = true
        let nextPage = currentPage + 1

        do {
            let response = try await fetchPage(serverURL: serverURL, page: nextPage)
            let newResults = response.results.filter { new in
                !results.contains { $0.uniqueID == new.uniqueID }
            }
            withAnimation {
                results.append(contentsOf: newResults)
            }
            currentPage = nextPage
            totalPages = response.totalPages
        } catch {
            print("Discover load more error: \(error)")
        }

        isLoading = false
    }

    private func fetchPage(serverURL: URL, page: Int) async throws -> SeerrPaginatedResponse<SeerrSearchResult> {
        switch selectedType {
        case .movies:
            return try await SeerrAPI.discoverMovies(serverURL: serverURL, page: page, filters: filters)
        case .shows:
            return try await SeerrAPI.discoverTV(serverURL: serverURL, page: page, filters: filters)
        }
    }
}
