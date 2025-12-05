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
    
    static func loadAllEpisodes(for show: BaseItemDto) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetEpisodesParameters()
        parameters.userID = context.userID
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        let request = Paths.getEpisodes(seriesID: show.id ?? "", parameters: parameters)
        return try await send(request).items ?? []
    }
    
    static func loadNextEpisode(after episode: BaseItemDto) async throws -> BaseItemDto? {
        guard episode.type == .episode,
              let seriesID = episode.seriesID else {
            return nil
        }
        
        var show = BaseItemDto()
        show.id = seriesID
        
        let allEpisodes = try await loadAllEpisodes(for: show)
            .sorted { episodeSortComparator(lhs: $0, rhs: $1) }
        
        guard let currentIndex = allEpisodes.firstIndex(where: { candidate in
            matches(candidate, with: episode)
        }) else {
            return nil
        }
        
        let nextIndex = allEpisodes.index(after: currentIndex)
        guard nextIndex < allEpisodes.count else {
            return nil
        }
        
        return allEpisodes[nextIndex]
    }
}

private extension JFAPI {
    static func episodeSortComparator(lhs: BaseItemDto, rhs: BaseItemDto) -> Bool {
        let lhsSeason = lhs.parentIndexNumber ?? Int.max
        let rhsSeason = rhs.parentIndexNumber ?? Int.max
        
        if lhsSeason == rhsSeason {
            return (lhs.indexNumber ?? Int.max) < (rhs.indexNumber ?? Int.max)
        }
        
        return lhsSeason < rhsSeason
    }
    
    static func matches(_ candidate: BaseItemDto, with target: BaseItemDto) -> Bool {
        if let targetID = target.id, let candidateID = candidate.id {
            return candidateID == targetID
        }
        
        let sameSeason = candidate.seasonID == target.seasonID
        let sameEpisodeNumber = candidate.indexNumber == target.indexNumber
        return sameSeason && sameEpisodeNumber
    }
}
