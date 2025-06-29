//
//  JFAPI+Resume.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 29/06/2025.
//

import Foundation
import JellyfinAPI
import Get

extension JFAPI {
    /// Loads resume items for the current user, returning only the most recent episode per show (and all movies)
    /// - Returns: Array of BaseItemDto representing resume items (max 20, one per show for episodes)
    func loadResumeItems() async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetResumeItemsParameters()
        parameters.userID = context.user.id
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [.movie, .episode]
        parameters.limit = 100 // fetch more to allow grouping, then limit to 20 after grouping
        let request = Paths.getResumeItems(parameters: parameters)
        let response = try await context.client.send(request)
        let items = response.value.items ?? []

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
