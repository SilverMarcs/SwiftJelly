//
//  ImageURLProvider.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import Foundation
import JellyfinAPI

enum ImageURLProvider {
    /// Generates the primary image URL for a BaseItemDto with fallback logic
    /// - Parameters:
    ///   - item: The BaseItemDto to get image for
    ///   - type: Preferred image type (default: .primary)
    /// - Returns: URL for the image or nil if not available
    static func imageURL(
        for item: BaseItemDto,
        type: ImageType = .primary
    ) -> URL? {
        guard let id = item.id else { return nil }

        // Episodes always use primary
        let imageType = (item.type == .episode) ? .primary : type
        return url(forItemID: id, imageType: imageType)
    }

    /// - Parameters:
    ///   - person: The BaseItemPerson to get image for
    /// - Returns: URL for the person's image or nil if not available
    static func personImageURL(for person: BaseItemPerson) -> URL? {
        guard let id = person.id else { return nil }

        return url(forItemID: id, imageType: .primary)
    }
}

private extension ImageURLProvider {
    static func url(forItemID id: String, imageType: ImageType) -> URL? {
        guard let client = try? JFAPI.getClient() else { return nil }
        let request = Paths.getItemImage(itemID: id, imageType: imageType.rawValue)
        return client.fullURL(with: request)
    }
}
