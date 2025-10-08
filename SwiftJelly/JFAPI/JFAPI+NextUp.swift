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
        async let resumeItemsRaw = loadResumeItems(limit: 10)
        async let nextUpItemsRaw = loadNextUpItems(limit: 10)
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

        // Combine and sort by last played date (resume) or premiere date (next up)
        var combined = Array(showToResume.values) + movies
        combined.sort { (lhs, rhs) in
            let lhsDate = lhs.userData?.lastPlayedDate ?? lhs.premiereDate ?? Date.distantPast
            let rhsDate = rhs.userData?.lastPlayedDate ?? rhs.premiereDate ?? Date.distantPast
            return lhsDate > rhsDate
        }
        return Array(combined)
    }
    
    /// Loads Next Up items for the current server (episodes to continue watching)
    /// - Returns: Array of BaseItemDto representing next up items without watch progress
    static func loadNextUpItems(limit: Int = 10) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetNextUpParameters()
        parameters.userID = context.userID
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.limit = limit
        let request = Paths.getNextUp(parameters: parameters)
        let items = try await send(request).items ?? []
        
        return items
    }
    
    static func loadResumeItems(limit: Int = 10) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetResumeItemsParameters()
        parameters.userID = context.userID
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.limit = limit
        let items = try await send(Paths.getResumeItems(parameters: parameters)).items ?? []

        return items
    }
}
