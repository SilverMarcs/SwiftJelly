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
        let imageType = (item.type == .episode || item.collectionType != nil) ? .primary : type
        
        if let tags = item.backdropImageTags, type == .backdrop, !tags.isEmpty {
            return url(forItemID: id, imageType: imageType)
        }
        
        if let tags = item.parentLogoImageTag, type == .backdrop, !tags.isEmpty {
            return url(forItemID: id, imageType: imageType)
        }

        // Check if the item has the required image tag
        if let tag = item.imageTags?[imageType.rawValue], !tag.isEmpty {
            return url(forItemID: id, imageType: imageType)
        }
        
        return nil
    }

    /// - Parameters:
    ///   - person: The BaseItemPerson to get image for
    /// - Returns: URL for the person's image or nil if not available
    static func personImageURL(for personId: String?) -> URL? {
        guard let id = personId else { return nil }

        return url(forItemID: id, imageType: .primary)
    }

    static func genreImageURL(forGenreName name: String) -> URL? {
        guard let client = try? JFAPI.getClient() else { return nil }
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }

        let request = Paths.getGenreImage(name: encodedName, imageType: ImageType.primary.rawValue)
        return client.fullURL(with: request, queryAPIKey: true)
    }
}

private extension ImageURLProvider {
    static func url(forItemID id: String, imageType: ImageType) -> URL? {
        guard let client = try? JFAPI.getClient() else { return nil }
        let request = Paths.getItemImage(itemID: id, imageType: imageType.rawValue)
        return client.fullURL(with: request)
    }
}
