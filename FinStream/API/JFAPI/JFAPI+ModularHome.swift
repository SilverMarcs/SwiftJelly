//
//  JFAPI+ModularHome.swift
//  FinStream
//

import Get
import JellyfinAPI

enum ModularHomeTrendingSection: String, Sendable {
    case movies = "TREND_MOVIES"
    case shows = "TREND_SHOWS"

    fileprivate var additionalData: String {
        switch self {
        case .movies:
            "1. Trending Movies"
        case .shows:
            "2. Trending Shows"
        }
    }
}

extension JFAPI {
    /// Loads a trending row supplied by the optional Home Screen Sections plugin.
    /// This is not part of Jellyfin's standard API.
    static func loadModularHomeTrending(
        _ section: ModularHomeTrendingSection,
        limit: Int? = nil
    ) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        let request = Request<BaseItemDtoQueryResult>(
            path: "/HomeScreen/Section/\(section.rawValue)",
            query: [
                ("UserId", context.userID),
                ("AdditionalData", section.additionalData),
            ]
        )
        let items = try await send(request).items ?? []

        guard let limit else { return items }
        return Array(items.prefix(limit))
    }

    /// Produces the shared ordered feed used by the hero and tvOS Top Shelf.
    static func loadModularHomeTrending(limitPerSection: Int = 10) async throws -> [BaseItemDto] {
        async let movies = loadModularHomeTrending(.movies, limit: limitPerSection)
        async let shows = loadModularHomeTrending(.shows, limit: limitPerSection)
        let trendingItems = interleave(try await movies, try await shows)
        return await hydrateSlideshowItems(trendingItems)
    }

    /// Hydrates every slideshow item in one standard Jellyfin request while
    /// retaining the ordering supplied by the Home Screen Sections plugin.
    private static func hydrateSlideshowItems(_ items: [BaseItemDto]) async -> [BaseItemDto] {
        var seenIDs = Set<String>()
        let itemIDs = items.compactMap(\.id).filter { seenIDs.insert($0).inserted }
        guard !itemIDs.isEmpty else { return items }

        do {
            let context = try getAPIContext()
            var parameters = Paths.GetItemsByUserIDParameters()
            parameters.ids = itemIDs
            parameters.enableUserData = true
            parameters.fields = [.overview, .genres]

            let request = Paths.getItemsByUserID(userID: context.userID, parameters: parameters)
            let hydratedItems = try await send(request).items ?? []
            let hydratedByID = Dictionary(
                hydratedItems.compactMap { item in
                    item.id.map { ($0, item) }
                },
                uniquingKeysWith: { first, _ in first }
            )

            return items.map { item in
                guard let id = item.id else { return item }
                return hydratedByID[id] ?? item
            }
        } catch {
            // The sparse plugin response is still usable if optional hydration fails.
            return items
        }
    }

    private static func interleave(
        _ movies: [BaseItemDto],
        _ shows: [BaseItemDto]
    ) -> [BaseItemDto] {
        var result: [BaseItemDto] = []
        result.reserveCapacity(movies.count + shows.count)

        for index in 0..<max(movies.count, shows.count) {
            if movies.indices.contains(index) {
                result.append(movies[index])
            }
            if shows.indices.contains(index) {
                result.append(shows[index])
            }
        }

        return result
    }
}
