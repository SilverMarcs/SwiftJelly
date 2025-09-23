import Foundation
import JellyfinAPI
import Get

extension JFAPI {
    static func loadSeasons(for show: BaseItemDto) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetSeasonsParameters()
        parameters.userID = context.userID
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        let request = Paths.getSeasons(seriesID: show.id ?? "", parameters: parameters)
        return try await send(request).items ?? []
    }
    
    static func loadEpisodes(for show: BaseItemDto, season: BaseItemDto) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetEpisodesParameters()
        parameters.userID = context.userID
        parameters.seasonID = season.id
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        let request = Paths.getEpisodes(seriesID: show.id ?? "", parameters: parameters)
        return try await send(request).items ?? []
    }
    
    static func loadNextEpisode(for show: BaseItemDto) async -> BaseItemDto? {
        let seasons = try? await loadSeasons(for: show)
        guard let seasons = seasons, !seasons.isEmpty else { return nil }
        
        let sortedSeasons = seasons.sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }
        
        // Try per season in order
        for season in sortedSeasons {
            let episodes = try? await loadEpisodes(for: show, season: season)
            guard let episodes = episodes else { continue }
            let sortedEpisodes = episodes.sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }
            
            // Prefer in-progress but not finished
            if let inProgress = sortedEpisodes.first(where: { ep in
                let hasProgress = (ep.userData?.playbackPositionTicks ?? 0) > 0
                let isFullyWatched = ep.userData?.isPlayed == true || (ep.playbackProgress ?? 0) >= 0.95
                return hasProgress && !isFullyWatched
            }) {
                return inProgress
            }
            
            // First fully-unwatched
            if let firstUnwatched = sortedEpisodes.first(where: { ep in
                let isWatched = ep.userData?.isPlayed == true || (ep.playbackProgress ?? 0) >= 0.95
                return !isWatched
            }) {
                return firstUnwatched
            }
            
            // else: this season finished, continue
        }
        
        // All watched: choose last episode of last season
        if let lastSeason = sortedSeasons.last {
            let episodes = try? await loadEpisodes(for: show, season: lastSeason)
            if let last = episodes?.sorted(by: { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }).last {
                return last
            }
        }
        
        return nil
    }
}
