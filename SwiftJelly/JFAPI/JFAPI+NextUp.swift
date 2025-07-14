//
//  JFAPI+NextUp.swift
//  SwiftJelly
//
//  Created by Copilot on 01/07/2025.
//

import Foundation
import JellyfinAPI
import Get

extension JFAPI {
    /// Loads items for the Continue Watching section: for each show, if there is an in-progress episode, show that; otherwise, show the next up episode. Movies are always included. Deduplicates by show.
    static func loadContinueWatchingSmart() async throws -> [BaseItemDto] {
        async let resumeItemsRaw = loadResumeItems()
        async let nextUpItemsRaw = loadNextUpItems(limit: 40)
        let resumeItems = try await resumeItemsRaw
        let nextUpItems = try await nextUpItemsRaw

        // Group resume episodes by seriesID, movies by id
        var showToResume: [String: BaseItemDto] = [:]
        var movies: [BaseItemDto] = []
        for item in resumeItems {
            switch item.type {
            case .episode:
                if let seriesID = item.seriesID {
                    showToResume[seriesID] = item
                }
            case .movie:
                movies.append(item)
            default:
                continue
            }
        }

        // For each next up, if the show is not already in showToResume, add it
        for item in nextUpItems {
            if let seriesID = item.seriesID, showToResume[seriesID] == nil {
                showToResume[seriesID] = item
            }
        }

        // Combine and sort by last played date (resume) or premiere date (next up), then limit to 20
        var combined = Array(showToResume.values) + movies
        combined.sort { (lhs, rhs) in
            let lhsDate = lhs.userData?.lastPlayedDate ?? lhs.premiereDate ?? Date.distantPast
            let rhsDate = rhs.userData?.lastPlayedDate ?? rhs.premiereDate ?? Date.distantPast
            return lhsDate > rhsDate
        }
        return Array(combined.prefix(20))
    }
    
    /// Loads Next Up items for the current server (episodes to continue watching)
    /// - Returns: Array of BaseItemDto representing next up items without watch progress
    static func loadNextUpItems(limit: Int = 20) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetNextUpParameters()
        parameters.userID = context.userID
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.limit = limit
        let request = Paths.getNextUp(parameters: parameters)
        let items = try await send(request).items ?? []
        
        // Filter out items with watch progress
        return items.filter { item in
            guard let ticks = item.userData?.playbackPositionTicks, let runtime = item.runTimeTicks, runtime > 0 else {
                // If no watchtime data, include the item
                return true
            }
            // Exclude if any watchtime (only include unwatched items)
            return ticks == 0
        }
    }
    
    static func loadResumeItems() async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetResumeItemsParameters()
        parameters.userID = context.userID
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [.movie, .episode]
        parameters.limit = 100 // fetch more to allow grouping, then limit to 20 after grouping
        let items = try await send(Paths.getResumeItems(parameters: parameters)).items ?? []

        // Group episodes by seriesID, pick most recent per show; include all movies
        var mostRecentEpisodes: [String: BaseItemDto] = [:]
        var movies: [BaseItemDto] = []

        for item in items {
            switch item.type {
            case .episode:
                if let seriesID = item.seriesID {
                    let current = mostRecentEpisodes[seriesID]
                    let isNewer: Bool = {
                        guard let current = current else { return true }
                        let lhs = item.userData?.lastPlayedDate ?? item.userData?.playbackPositionTicks.map { Date(timeIntervalSince1970: TimeInterval($0) / 10_000_000) } ?? Date.distantPast
                        let rhs = current.userData?.lastPlayedDate ?? current.userData?.playbackPositionTicks.map { Date(timeIntervalSince1970: TimeInterval($0) / 10_000_000) } ?? Date.distantPast
                        return lhs > rhs
                    }()
                    if isNewer {
                        mostRecentEpisodes[seriesID] = item
                    }
                }
            case .movie:
                movies.append(item)
            default:
                continue
            }
        }

        // Combine and sort by last played date descending, then limit to 20
        var combined = Array(mostRecentEpisodes.values) + movies
        combined.sort { (lhs, rhs) in
            let lhsDate = lhs.userData?.lastPlayedDate ?? lhs.userData?.playbackPositionTicks.map { Date(timeIntervalSince1970: TimeInterval($0) / 10_000_000) } ?? Date.distantPast
            let rhsDate = rhs.userData?.lastPlayedDate ?? rhs.userData?.playbackPositionTicks.map { Date(timeIntervalSince1970: TimeInterval($0) / 10_000_000) } ?? Date.distantPast
            return lhsDate > rhsDate
        }
        return Array(combined.prefix(20))
    }
}
