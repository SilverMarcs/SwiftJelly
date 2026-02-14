//
//  JFAPI+NextUp.swift
//  SwiftJelly
//
//  Created by Copilot on 01/07/2025.
//

import Foundation
@preconcurrency import JellyfinAPI
import Get

extension JFAPI {
    /// Loads items for the Continue Watching section with smarter prioritization.
    /// - We keep the newest in-progress episode per show.
    /// - If the user watched a newer episode afterwards (so Jellyfin's NextUp is ahead of the unfinished one),
    ///   we show the newer NextUp episode instead of the stale unfinished entry.
    /// - NextUp items are sorted by when their *previous* episode was played, since the
    ///   NextUp items themselves are unplayed and have no `lastPlayedDate`.
    /// - Movies remain deduplicated by id.
    static func loadContinueWatchingSmart() async throws -> [BaseItemDto] {
        let fetchLimit = 10
        async let resumeItemsRaw = loadResumeItems(limit: fetchLimit)
        async let nextUpItemsRaw = loadNextUpItems(limit: fetchLimit)
        let resumeItems = try await resumeItemsRaw
        let nextUpItems = try await nextUpItemsRaw

        // Group resume episodes by seriesID, movies by id
        var resumeEpisodesBySeries: [String: [BaseItemDto]] = [:]
        var movies: [BaseItemDto] = []
        for item in resumeItems {
            switch item.type {
            case .episode:
                if let seriesID = item.seriesID {
                    resumeEpisodesBySeries[seriesID, default: []].append(item)
                }
            case .movie:
                movies.append(item)
            default:
                continue
            }
        }

        // Map of seriesID -> next up
        var nextUpEpisodesBySeries: [String: BaseItemDto] = [:]
        for item in nextUpItems where item.type == .episode {
            if let seriesID = item.seriesID {
                nextUpEpisodesBySeries[seriesID] = item
            }
        }

        // For each NextUp item, load the previous episode's played date so we know
        // when the user last engaged with that series. This is done in a single
        // concurrent batch (one getEpisodes call per series using adjacentTo).
        let previousEpisodeDates = await loadPreviousEpisodeDates(for: nextUpEpisodesBySeries)

        var combinedEpisodes: [BaseItemDto] = []

        for (seriesID, resumeEpisodes) in resumeEpisodesBySeries {
            let latestResume = latestResumeEpisode(from: resumeEpisodes)
            let nextUp = nextUpEpisodesBySeries.removeValue(forKey: seriesID)

            if let decision = chooseEpisode(
                latestResume: latestResume,
                nextUp: nextUp,
                previousEpisodeDates: previousEpisodeDates
            ) {
                combinedEpisodes.append(decision)
            }
        }

        // Add remaining shows that only have Next Up entries
        combinedEpisodes.append(contentsOf: nextUpEpisodesBySeries.values)

        // Add movies once
        combinedEpisodes.append(contentsOf: movies)

        // Sort by most recent activity, using previous-episode dates for NextUp items
        combinedEpisodes.sort {
            let lhsDate = smartActivityDate(for: $0, previousEpisodeDates: previousEpisodeDates)
            let rhsDate = smartActivityDate(for: $1, previousEpisodeDates: previousEpisodeDates)
            return lhsDate > rhsDate
        }
        return Array(combinedEpisodes)
    }
    
    /// Loads Next Up items for the current server (episodes to continue watching)
    /// - Parameters:
    ///   - limit: Maximum number of items to return
    ///   - seriesID: Optional series ID to filter results
    /// - Returns: Array of BaseItemDto representing next up items
    static func loadNextUpItems(limit: Int = 10, seriesID: String? = nil) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetNextUpParameters()
        parameters.userID = context.userID
        parameters.enableUserData = true
        parameters.enableResumable = false
        parameters.fields = .MinimumFields
        parameters.limit = limit
        parameters.seriesID = seriesID
        let request = Paths.getNextUp(parameters: parameters)
        let items = try await send(request).items ?? []
        
        return items
    }
    
    /// Loads resume items (in-progress content)
    /// - Parameters:
    ///   - limit: Maximum number of items to return
    ///   - parentID: Optional parent ID to filter results (e.g., series ID for episodes)
    /// - Returns: Array of BaseItemDto representing resume items
    static func loadResumeItems(limit: Int = 10, parentID: String? = nil) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetResumeItemsParameters()
        parameters.userID = context.userID
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.limit = limit
        parameters.parentID = parentID
        let items = try await send(Paths.getResumeItems(parameters: parameters)).items ?? []

        return items
    }
    
    private static func latestResumeEpisode(from episodes: [BaseItemDto]) -> BaseItemDto? {
        episodes.sorted { activityDate(for: $0) > activityDate(for: $1) }.first
    }
    
    /// For each NextUp item, loads the adjacent episodes to find the previous episode's
    /// `lastPlayedDate`. Returns a mapping from NextUp item ID to that date.
    /// All series are fetched concurrently.
    private static func loadPreviousEpisodeDates(
        for nextUpBySeries: [String: BaseItemDto]
    ) async -> [String: Date] {
        await withTaskGroup(of: (String, Date?).self) { group in
            for (seriesID, nextUpItem) in nextUpBySeries {
                guard let nextUpID = nextUpItem.id else { continue }
                group.addTask {
                    do {
                        let context = try await getAPIContext()
                        var parameters = Paths.GetEpisodesParameters()
                        parameters.userID = await context.userID
                        parameters.adjacentTo = nextUpID
                        parameters.enableUserData = true
                        parameters.fields = await .MinimumFields
                        let request = Paths.getEpisodes(seriesID: seriesID, parameters: parameters)
                        let episodes = try await send(request).items ?? []

                        // adjacentTo returns episodes surrounding the target in episode order.
                        // Sort by season then episode number to be safe, then find the one
                        // right before the NextUp item.
                        let sorted = episodes.sorted {
                            let lhsSeason = $0.parentIndexNumber ?? Int.max
                            let rhsSeason = $1.parentIndexNumber ?? Int.max
                            if lhsSeason != rhsSeason { return lhsSeason < rhsSeason }
                            return ($0.indexNumber ?? Int.max) < ($1.indexNumber ?? Int.max)
                        }

                        if let nextUpIndex = sorted.firstIndex(where: { $0.id == nextUpID }),
                           nextUpIndex > 0 {
                            let previousEpisode = sorted[nextUpIndex - 1]
                            return (nextUpID, previousEpisode.userData?.lastPlayedDate)
                        }

                        return (nextUpID, nil)
                    } catch {
                        return (nextUpID, nil)
                    }
                }
            }

            var result: [String: Date] = [:]
            for await (itemID, date) in group {
                if let date {
                    result[itemID] = date
                }
            }
            return result
        }
    }

    private static func chooseEpisode(
        latestResume: BaseItemDto?,
        nextUp: BaseItemDto?,
        previousEpisodeDates: [String: Date]
    ) -> BaseItemDto? {
        switch (latestResume, nextUp) {
        case (nil, nil):
            return nil
        case let (resume?, nil):
            return resume
        case let (nil, nextEpisode?):
            return nextEpisode
        case let (resume?, nextEpisode?):
            let resumeDate = activityDate(for: resume)
            let nextDate = smartActivityDate(for: nextEpisode, previousEpisodeDates: previousEpisodeDates)
            return nextDate > resumeDate ? nextEpisode : resume
        }
    }

    /// Returns the best activity date for an item, using the previous episode's played date
    /// for NextUp items that have no `lastPlayedDate` of their own.
    private static func smartActivityDate(
        for item: BaseItemDto,
        previousEpisodeDates: [String: Date]
    ) -> Date {
        if let itemID = item.id, let previousDate = previousEpisodeDates[itemID] {
            return previousDate
        }
        return activityDate(for: item)
    }

    private static func activityDate(for item: BaseItemDto) -> Date {
        if let played = item.userData?.lastPlayedDate {
            return played
        }
        if let ticks = item.userData?.playbackPositionTicks, ticks > 0 {
            // Jellyfin sometimes omits lastPlayedDate for brand-new in-progress items.
            return Date()
        }
        return item.premiereDate
        ?? item.dateCreated
        ?? Date.distantPast
    }
}
