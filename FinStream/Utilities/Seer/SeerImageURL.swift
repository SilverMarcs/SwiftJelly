//
//  SeerImageURL.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation
import JellyfinAPI

enum SeerImageURL {
    private static let baseURL = URL(string: "https://image.tmdb.org/t/p")

    enum Size: String {
        case poster = "w500"
        case backdrop = "w1280"
        case still = "w780"
        case profile = "w185"
    }

    static func url(path: String?, size: Size) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return baseURL?.appending(path: size.rawValue).appending(path: path)
    }

    static func url(for item: BaseItemDto, type: ImageType) -> URL? {
        switch type {
        case .backdrop, .thumb:
            if item.type == .episode {
                return url(path: item.imageTags?[ImageType.primary.rawValue], size: .still)
            }
            return url(path: item.backdropImageTags?.first, size: .backdrop)
        case .primary:
            let size: Size = item.type == .episode ? .still : .poster
            return url(path: item.imageTags?[ImageType.primary.rawValue], size: size)
        default:
            return nil
        }
    }
}
