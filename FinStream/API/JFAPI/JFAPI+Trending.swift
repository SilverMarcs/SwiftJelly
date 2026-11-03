//
//  JFAPI+Trending.swift
//  FinStream
//

import Get
import JellyfinAPI

extension JFAPI {
    /// Loads the "Trending Movies" and "Trending Shows" rows from the optional
    /// Home Screen Sections plugin, interleaved as movie, show, movie, show…
    ///
    /// Rows are looked up by name because the plugin assigns generated IDs.
    /// Throws on servers without the plugin.
    static func loadTrending(limitPerRow: Int = 10) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        let sections = try await send(
            Request<HomeScreenSection.List>(
                path: "/HomeScreen/Sections",
                query: [("UserId", context.userID)]
            )
        ).items

        async let movies = loadSection(named: "Trending Movies", in: sections, limit: limitPerRow)
        async let shows = loadSection(named: "Trending Shows", in: sections, limit: limitPerRow)
        return try await hydrate(interleave(movies, shows))
    }

    private static func loadSection(
        named name: String,
        in sections: [HomeScreenSection],
        limit: Int
    ) async throws -> [BaseItemDto] {
        guard let section = sections.first(where: { $0.displayText?.lowercased() == name.lowercased() }) else {
            return []
        }

        let context = try getAPIContext()
        var query = [("UserId", context.userID)]
        if let additionalData = section.additionalData {
            query.append(("AdditionalData", additionalData))
        }
        let request = Request<BaseItemDtoQueryResult>(
            path: "/HomeScreen/Section/\(section.section)",
            query: query
        )
        return Array((try await send(request).items ?? []).prefix(limit))
    }

    /// Plugin rows omit fields the hero needs (overview, genres), so refetch
    /// the items in one standard request while keeping the row order.
    private static func hydrate(_ items: [BaseItemDto]) async throws -> [BaseItemDto] {
        let ids = items.compactMap(\.id)
        guard !ids.isEmpty else { return [] }

        let context = try getAPIContext()
        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.ids = ids
        parameters.enableUserData = true
        parameters.fields = [.overview, .genres]
        let request = Paths.getItemsByUserID(userID: context.userID, parameters: parameters)
        let hydrated = try await send(request).items ?? []

        return ids.compactMap { id in hydrated.first { $0.id == id } }
    }

    private static func interleave(_ first: [BaseItemDto], _ second: [BaseItemDto]) -> [BaseItemDto] {
        (0..<max(first.count, second.count)).flatMap { index in
            [first, second].compactMap { $0.indices.contains(index) ? $0[index] : nil }
        }
    }
}
