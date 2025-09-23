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
        let client: JellyfinClient
        do {
            client = try JFAPI.getClient()
        } catch {
            return nil
        }
        // For episodes, try to get landscape images (thumb/backdrop) from series
        if item.type == .episode, let seriesId = item.seriesID {
            // Try thumb image from series first
            if let thumbTag = getImageTag(for: .thumb, from: item) {
                let parameters = Paths.GetItemImageParameters(tag: thumbTag)
                let request = Paths.getItemImage(
                    itemID: seriesId,
                    imageType: ImageType.thumb.rawValue,
                    parameters: parameters
                )
                return client.fullURL(with: request)
            }
            // Try backdrop image from series
            if let backdropTag = item.backdropImageTags?.first {
                let parameters = Paths.GetItemImageParameters(tag: backdropTag)
                let request = Paths.getItemImage(
                    itemID: seriesId,
                    imageType: ImageType.backdrop.rawValue,
                    parameters: parameters
                )
                return client.fullURL(with: request)
            }
        }
        // Try preferred type first
        if let preferredTag = getImageTag(for: type, from: item) {
            let parameters = Paths.GetItemImageParameters(tag: preferredTag)
            let request = Paths.getItemImage(
                itemID: id,
                imageType: type.rawValue,
                parameters: parameters
            )
            return client.fullURL(with: request)
        }
        // Fallback order: thumb -> backdrop -> primary
        let fallbackTypes: [ImageType] = [.thumb, .backdrop, .primary]
        for imageType in fallbackTypes {
            if imageType == type { continue }
            if let tag = getImageTag(for: imageType, from: item) {
                let parameters = Paths.GetItemImageParameters(tag: tag)
                let request = Paths.getItemImage(
                    itemID: id,
                    imageType: imageType.rawValue,
                    parameters: parameters
                )
                return client.fullURL(with: request)
            }
        }
        return nil
    }
    
    /// - Parameters:
    ///   - person: The BaseItemPerson to get image for
    /// - Returns: URL for the person's image or nil if not available
    static func personImageURL(
        for person: BaseItemPerson
    ) -> URL? {
        guard let id = person.id, let primaryImageTag = person.primaryImageTag else { return nil }
        
        let client: JellyfinClient
        do {
            client = try JFAPI.getClient()
        } catch {
            return nil
        }
        
        let parameters = Paths.GetItemImageParameters(tag: primaryImageTag)
        
        let request = Paths.getItemImage(
            itemID: id,
            imageType: ImageType.primary.rawValue,
            parameters: parameters
        )
        
        return client.fullURL(with: request)
    }

    private static func getImageTag(for type: ImageType, from item: BaseItemDto) -> String? {
        switch type {
        case .backdrop:
            return item.backdropImageTags?.first
        case .screenshot:
            return item.screenshotImageTags?.first
        default:
            return item.imageTags?[type.rawValue]
        }
    }
}
