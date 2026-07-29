//
//  JFAPI+MediaSegments.swift
//  SwiftJelly
//
//  Fetches media segments (intro/outro/recap ranges) provided by server
//  plugins such as the Intro Skipper plugin. These segments come from the
//  `/MediaSegments/{itemId}` endpoint, NOT from item chapters.
//

import Foundation
import JellyfinAPI
import Get

/// The type of content a media segment represents.
/// Mirrors the server's `MediaSegmentType` schema.
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

/// A single media segment as returned by the `/MediaSegments/{itemId}` endpoint.
/// The server serializes keys in PascalCase, so we map them explicitly.
nonisolated struct MediaSegmentDto: Decodable {
    var type: MediaSegmentType
    var startTicks: Int64?
    var endTicks: Int64?

    private enum CodingKeys: String, CodingKey {
        case type = "Type"
        case startTicks = "StartTicks"
        case endTicks = "EndTicks"
    }

    /// Segment start in seconds, if available.
    var startSeconds: Double? {
        guard let startTicks else { return nil }
        return Double(startTicks) / 10_000_000
    }

    /// Segment end in seconds, if available.
    var endSeconds: Double? {
        guard let endTicks else { return nil }
        return Double(endTicks) / 10_000_000
    }
}

/// Query result container for media segments.
private nonisolated struct MediaSegmentDtoQueryResult: Decodable {
    var items: [MediaSegmentDto]?

    private enum CodingKeys: String, CodingKey {
        case items = "Items"
    }
}

extension JFAPI {

    /// Fetches media segments (intro/outro/recap ranges) for the given item.
    /// These are typically provided by the Intro Skipper plugin.
    /// - Parameter item: The item being played.
    /// - Returns: Array of media segments, empty if none are available.
    static func getMediaSegments(for item: BaseItemDto) async throws -> [MediaSegmentDto] {
        guard let itemID = item.id else {
            return []
        }

        let context = try getAPIContext()

        // GET /MediaSegments/{itemId} -> MediaSegmentDtoQueryResult
        let path = "/MediaSegments/\(itemID)"
        let request = Request<MediaSegmentDtoQueryResult>(path: path)

        let response = try await context.client.send(request)
        return response.value.items ?? []
    }
}
