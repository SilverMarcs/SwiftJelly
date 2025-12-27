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
    /// Loads items for the Continue Watching section with smarter prioritization.
    /// - We keep the newest in-progress episode per show.
    /// - If the user watched a newer episode afterwards (so Jellyfin's NextUp is ahead of the unfinished one),
    ///   we show the newer NextUp episode instead of the stale unfinished entry.
    /// - Movies remain deduplicated by id.
    static func loadContinueWatchingSmart() async throws -> [BaseItemDto] {
        // Ask Jellyfin for a generous window so newly-started episodes
        // aren’t trimmed server-side (we will trim to 20 after ranking).
        let fetchLimit = 50
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
        
        var combinedEpisodes: [BaseItemDto] = []
        
        for (seriesID, resumeEpisodes) in resumeEpisodesBySeries {
            let latestResume = latestResumeEpisode(from: resumeEpisodes)
            let nextUp = nextUpEpisodesBySeries.removeValue(forKey: seriesID)
            
            if let decision = chooseEpisode(latestResume: latestResume, nextUp: nextUp) {
                combinedEpisodes.append(decision)
            }
        }
        
        // Add remaining shows that only have Next Up entries
        combinedEpisodes.append(contentsOf: nextUpEpisodesBySeries.values)
        
        // Add movies once
        combinedEpisodes.append(contentsOf: movies)
        
        // Sort by most recent activity (last played / premiere)
        combinedEpisodes.sort {
            let lhsDate = activityDate(for: $0)
            let rhsDate = activityDate(for: $1)
            return lhsDate > rhsDate
        }
        return Array(combinedEpisodes.prefix(20))
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
    
    private static func chooseEpisode(latestResume: BaseItemDto?, nextUp: BaseItemDto?) -> BaseItemDto? {
        switch (latestResume, nextUp) {
        case (nil, nil):
            return nil
        case let (resume?, nil):
            return resume
        case let (nil, nextEpisode?):
            return nextEpisode
        case let (resume?, nextEpisode?):
            let resumeDate = activityDate(for: resume)
            let nextDate = nextUpReferenceDate(for: nextEpisode)
            return nextDate > resumeDate ? nextEpisode : resume
        }
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
    
    private static func nextUpReferenceDate(for item: BaseItemDto) -> Date {
        item.userData?.lastPlayedDate
        ?? item.premiereDate
        ?? item.dateCreated
        ?? Date.distantPast
    }
}
