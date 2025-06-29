import Foundation
import JellyfinAPI
import Get

extension JFAPI {
    func loadSeasons(for show: BaseItemDto) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetSeasonsParameters()
        parameters.userID = context.user.id
        parameters.enableUserData = true
        let request = Paths.getSeasons(seriesID: show.id ?? "", parameters: parameters)
        let response = try await context.client.send(request)
        return response.value.items ?? []
    }
    
    func loadEpisodes(for show: BaseItemDto, season: BaseItemDto) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetEpisodesParameters()
        parameters.userID = context.user.id
        parameters.seasonID = season.id
        parameters.enableUserData = true
        let request = Paths.getEpisodes(seriesID: show.id ?? "", parameters: parameters)
        let response = try await context.client.send(request)
        return response.value.items ?? []
    }
}
