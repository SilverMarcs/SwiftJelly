//
//  ImageSource.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import Foundation

struct ImageSource: Hashable {
    let url: URL?
    let blurHash: String?
    
    init(url: URL?, blurHash: String? = nil) {
        self.url = url
        self.blurHash = blurHash
    }
}

extension MediaItem {
    
    func imageURL(
        for server: Server,
        type: ImageType,
        maxWidth: CGFloat? = nil,
        maxHeight: CGFloat? = nil
    ) -> URL? {
        guard let tag = getImageTag(for: type) else { return nil }
        
        var components = URLComponents(url: server.url, resolvingAgainstBaseURL: false)
        components?.path = "/Items/\(id)/Images/\(type.rawValue)"
        
        var queryItems: [URLQueryItem] = []
        
        if let maxWidth = maxWidth {
            queryItems.append(URLQueryItem(name: "maxWidth", value: String(Int(maxWidth))))
        }
        
        if let maxHeight = maxHeight {
            queryItems.append(URLQueryItem(name: "maxHeight", value: String(Int(maxHeight))))
        }
        
        queryItems.append(URLQueryItem(name: "tag", value: tag))
        queryItems.append(URLQueryItem(name: "quality", value: "90"))
        
        components?.queryItems = queryItems
        
        return components?.url
    }
    
    func imageSource(
        for server: Server,
        type: ImageType,
        maxWidth: CGFloat? = nil,
        maxHeight: CGFloat? = nil
    ) -> ImageSource {
        let url = imageURL(for: server, type: type, maxWidth: maxWidth, maxHeight: maxHeight)
        let blurHash = getBlurHash(for: type)
        
        return ImageSource(url: url, blurHash: blurHash)
    }
    
    // Get landscape image sources with fallbacks for continue watching
    func landscapeImageSources(for server: Server, maxWidth: CGFloat = 400) -> [ImageSource] {
        let imageTypes: [ImageType] = [.thumb, .backdrop, .primary]
        
        return imageTypes.compactMap { type in
            let source = imageSource(for: server, type: type, maxWidth: maxWidth)
            return source.url != nil ? source : nil
        }
    }
    
    // Get portrait image sources for posters
    func portraitImageSources(for server: Server, maxWidth: CGFloat = 300) -> [ImageSource] {
        let imageTypes: [ImageType] = [.primary, .poster, .art]
        
        return imageTypes.compactMap { type in
            let source = imageSource(for: server, type: type, maxWidth: maxWidth)
            return source.url != nil ? source : nil
        }
    }
    
    private func getImageTag(for type: ImageType) -> String? {
        switch type {
        case .backdrop:
            return backdropImageTags?.first
        case .screenshot:
            return screenshotImageTags?.first
        default:
            return imageTags?[type.rawValue]
        }
    }
    
    private func getBlurHash(for type: ImageType) -> String? {
        guard type != .logo else { return nil }
        
        if let tag = getImageTag(for: type),
           let taggedBlurHash = imageBlurHashes?[type.rawValue]?[tag] {
            return taggedBlurHash
        } else if let firstBlurHash = imageBlurHashes?[type.rawValue]?.values.first {
            return firstBlurHash
        }
        
        return nil
    }
}

// Add missing poster type
extension ImageType {
    static let poster = ImageType.primary
}
