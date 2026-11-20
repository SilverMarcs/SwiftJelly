//
//  JFAPI+MediaSegments.swift
//  SwiftJelly
//

import Foundation
import JellyfinAPI
import Get

nonisolated enum MediaSegmentType: String, Decodable {
    case unknown = "Unknown"
    case commercial = "Commercial"
    case preview = "Preview"
    case recap = "Recap"
    case outro = "Outro"
    case intro = "Intro"

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = MediaSegmentType(rawValue: raw) ?? .unknown
    }
}

/// The server serializes `/MediaSegments` keys in PascalCase.
nonisolated struct MediaSegmentDto: Decodable {
    var type: MediaSegmentType
    var startTicks: Int64?
    var endTicks: Int64?

    private enum CodingKeys: String, CodingKey {
        case type = "Type"
        case startTicks = "StartTicks"
        case endTicks = "EndTicks"
    }

    var startSeconds: Double? {
        startTicks.map { Double($0) / 10_000_000 }
    }

    var endSeconds: Double? {
        endTicks.map { Double($0) / 10_000_000 }
    }
}

private nonisolated struct MediaSegmentDtoQueryResult: Decodable {
    var items: [MediaSegmentDto]?

    private enum CodingKeys: String, CodingKey {
        case items = "Items"
    }
}

extension JFAPI {
    static func getMediaSegments(for item: BaseItemDto) async throws -> [MediaSegmentDto] {
        guard let itemID = item.id else { return [] }
        let request = Request<MediaSegmentDtoQueryResult>(path: "/MediaSegments/\(itemID)")
        return try await send(request).items ?? []
    }
}
