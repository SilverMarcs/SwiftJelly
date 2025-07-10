//
//  ImageURLProvider.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import Foundation
import JellyfinAPI

struct ImageURLProvider {
    /// Generates the primary image URL for a BaseItemDto with fallback logic
    /// - Parameters:
    ///   - item: The BaseItemDto to get image for
    ///   - maxWidth: Maximum width for the image (default: 600)
    ///   - preferredType: Preferred image type (default: .primary)
    /// - Returns: URL for the image or nil if not available
    static func imageURL(
        for item: BaseItemDto,
        maxWidth: CGFloat = 600,
        preferredType: ImageType = .primary
    ) -> URL? {
        guard let id = item.id else { return nil }
        let client: JellyfinClient
        do {
            client = try JFAPI.shared.getClient()
        } catch {
            return nil
        }
        // For episodes, try to get landscape images (thumb/backdrop) from series
        if item.type == .episode, let seriesId = item.seriesID {
            // Try thumb image from series first
            if let thumbTag = getImageTag(for: .thumb, from: item) {
                let parameters = Paths.GetItemImageParameters(
                    maxWidth: Int(maxWidth),
                    tag: thumbTag
                )
                let request = Paths.getItemImage(
                    itemID: seriesId,
                    imageType: ImageType.thumb.rawValue,
                    parameters: parameters
                )
                return client.fullURL(with: request)
            }
            // Try backdrop image from series
            if let backdropTag = item.backdropImageTags?.first {
                let parameters = Paths.GetItemImageParameters(
                    maxWidth: Int(maxWidth),
                    tag: backdropTag
                )
                let request = Paths.getItemImage(
                    itemID: seriesId,
                    imageType: ImageType.backdrop.rawValue,
                    parameters: parameters
                )
                return client.fullURL(with: request)
            }
        }
        // Try preferred type first
        if let preferredTag = getImageTag(for: preferredType, from: item) {
            let parameters = Paths.GetItemImageParameters(
                maxWidth: Int(maxWidth),
                tag: preferredTag
            )
            let request = Paths.getItemImage(
                itemID: id,
                imageType: preferredType.rawValue,
                parameters: parameters
            )
            return client.fullURL(with: request)
        }
        // Fallback order: thumb -> backdrop -> primary
        let fallbackTypes: [ImageType] = [.thumb, .backdrop, .primary]
        for imageType in fallbackTypes {
            if imageType == preferredType { continue }
            if let tag = getImageTag(for: imageType, from: item) {
                let parameters = Paths.GetItemImageParameters(
                    maxWidth: Int(maxWidth),
                    tag: tag
                )
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
    
    /// Generates a portrait image URL specifically for library items
    static func portraitImageURL(for item: BaseItemDto, maxWidth: CGFloat = 300) -> URL? {
        imageURL(for: item, maxWidth: maxWidth, preferredType: .primary)
    }
    /// Generates a landscape image URL specifically for continue watching cards
    static func landscapeImageURL(for item: BaseItemDto, maxWidth: CGFloat = 600) -> URL? {
        imageURL(for: item, maxWidth: maxWidth, preferredType: .thumb)
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
