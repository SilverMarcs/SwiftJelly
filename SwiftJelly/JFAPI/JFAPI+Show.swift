import Foundation
import JellyfinAPI
import Get

extension JFAPI {
    func loadSeasons(for show: BaseItemDto) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetSeasonsParameters()
        parameters.userID = context.userID
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        let request = Paths.getSeasons(seriesID: show.id ?? "", parameters: parameters)
        return try await send(request).items ?? []
    }
    
    func loadEpisodes(for show: BaseItemDto, season: BaseItemDto) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetEpisodesParameters()
        parameters.userID = context.userID
        parameters.seasonID = season.id
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        let request = Paths.getEpisodes(seriesID: show.id ?? "", parameters: parameters)
        return try await send(request).items ?? []
    }
}
