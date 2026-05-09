//
//  JFAPI+Downloads.swift
//  SwiftJelly
//

import Foundation
import JellyfinAPI

extension JFAPI {
    /// Builds a download URL that asks Jellyfin to deliver the item in an MP4
    /// container so AVPlayer can play it offline.
    ///
    /// `Static` is intentionally omitted — with `Static=true` the server
    /// returns the original file bytes and ignores the container override,
    /// which produced unplayable MKVs saved as `.mp4`. Without it the request
    /// runs through the stream pipeline; the copy flags let the server remux
    /// without re-encoding when codecs are MP4-compatible and transcode only
    /// the streams that aren't.
    static func downloadURL(for item: BaseItemDto) throws -> URL {
        guard let itemID = item.id, !itemID.isEmpty else {
            throw PlaybackError.missingItemID
        }
        let context = try getAPIContext()
        guard let token = context.server.accessToken else {
            throw JFAPIError.setupFailed
        }

        let parameters = Paths.GetVideoStreamParameters(
            container: "mp4",
            tag: item.etag,
            mediaSourceID: item.mediaSources?.first?.id ?? itemID,
            allowVideoStreamCopy: true,
            allowAudioStreamCopy: true
        )
        let request = Paths.getVideoStream(itemID: itemID, parameters: parameters)

        guard let baseURL = context.client.fullURL(with: request),
              var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw PlaybackError.invalidStreamURL
        }
        var query = components.queryItems ?? []
        query.append(URLQueryItem(name: "api_key", value: token))
        components.queryItems = query
        guard let url = components.url else {
            throw PlaybackError.invalidStreamURL
        }
        return url
    }
}
