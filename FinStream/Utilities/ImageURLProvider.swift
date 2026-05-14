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

    /// Builds a series image URL for episode items when available.
    static func seriesImageURL(for item: BaseItemDto) -> URL? {
        if let tag = item.parentThumbImageTag,
           let parentID = item.parentThumbItemID,
           !tag.isEmpty {
            return url(forItemID: parentID, imageType: .thumb)
        }

        return nil
    }

    /// Best-effort backdrop URL. For an episode this returns the *show's*
    /// backdrop (via `parentBackdropItemID`) rather than the episode's
    /// thumbnail; for movies it returns the item's own backdrop. Falls back
    /// to thumb / primary if a backdrop tag isn't present.
    static func bestBackdropURL(for item: BaseItemDto) -> URL? {
        if item.type == .episode {
            if let tags = item.parentBackdropImageTags, !tags.isEmpty,
               let parentID = item.parentBackdropItemID {
                return url(forItemID: parentID, imageType: .backdrop)
            }
            if let tag = item.parentThumbImageTag, !tag.isEmpty,
               let parentID = item.parentThumbItemID {
                return url(forItemID: parentID, imageType: .thumb)
            }
        }
        return imageURL(for: item, type: .backdrop)
            ?? imageURL(for: item, type: .thumb)
            ?? imageURL(for: item, type: .primary)
    }

    static func genreImageURL(forGenreName name: String) -> URL? {
        guard let client = try? JFAPI.getClient() else { return nil }
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }

        let request = Paths.getGenreImage(name: encodedName, imageType: ImageType.primary.rawValue)
        return client.fullURL(with: request, queryAPIKey: true)
    }

    static func chapterImageURL(
        for item: BaseItemDto,
        chapterIndex: Int,
        imageTag: String?
    ) -> URL? {
        guard let id = item.id else { return nil }
        guard let client = try? JFAPI.getClient() else { return nil }

        var parameters = Paths.GetItemImageParameters()
        parameters.tag = imageTag
        parameters.imageIndex = chapterIndex
        parameters.maxWidth = 800
        parameters.format = .jpg

        let request = Paths.getItemImage(itemID: id, imageType: ImageType.chapter.rawValue, parameters: parameters)
        return client.fullURL(with: request)
    }
}

private extension ImageURLProvider {
    static func url(forItemID id: String, imageType: ImageType) -> URL? {
        guard let client = try? JFAPI.getClient() else { return nil }
        let request = Paths.getItemImage(itemID: id, imageType: imageType.rawValue)
        return client.fullURL(with: request)
    }
}
