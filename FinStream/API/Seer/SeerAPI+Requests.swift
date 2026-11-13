//
//  SeerAPI+Requests.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation
import JellyfinAPI

extension SeerAPI {
    static func request(_ reference: SeerMediaReference, seasons: [Int]? = nil) async throws {
        let body = SeerRequestBody(
            mediaType: reference.mediaType,
            mediaID: reference.tmdbID,
            seasons: reference.mediaType == .tv ? seasons : nil
        )
        let _: SeerEmptyResponse = try await send(SeerEndpoint(path: "request", body: body))
    }

    static func userRequests(limit: Int = 20) async throws -> [SeerMediaRequest] {
        guard let userID = dataManager.server?.seer?.userID else {
            throw SeerAPIError.notConfigured
        }
        let page: SeerPage<SeerMediaRequest> = try await send(
            SeerEndpoint(path: "user/\(userID)/requests", query: ["take": String(limit), "skip": "0"])
        )
        return page.results
    }

    static func userRequestItems(limit: Int = 20) async throws -> [SeerRequestItem] {
        let requests = try await userRequests(limit: limit)
        let libraryItems = await SeerLibraryResolver.libraryItems(for: requests.compactMap(\.media.jellyfinMediaID))

        return await withTaskGroup(of: (Int, BaseItemDto?).self) { group in
            for request in requests {
                if let libraryItem = request.media.jellyfinMediaID.flatMap({ libraryItems[$0] }) {
                    group.addTask { (request.id, libraryItem) }
                } else {
                    group.addTask { (request.id, await mediaItem(for: request)) }
                }
            }

            var items: [Int: BaseItemDto] = [:]
            for await (id, item) in group {
                items[id] = item
            }
            return requests.compactMap { request in
                items[request.id].map { SeerRequestItem(request: request, item: $0) }
            }
        }
    }

    private static func mediaItem(for request: SeerMediaRequest) async -> BaseItemDto? {
        guard let reference = request.reference else { return nil }
        switch reference.mediaType {
        case .movie:
            return (try? await movie(id: reference.tmdbID)).map(BaseItemDto.init(seerMovie:))
        case .tv:
            return (try? await tv(id: reference.tmdbID)).map(BaseItemDto.init(seerShow:))
        }
    }
}
