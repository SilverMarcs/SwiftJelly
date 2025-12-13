//
//  BaseItemDto+Convenience.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 26/10/2025.
//

import Foundation
import JellyfinAPI

extension BaseItemDto {
    var seasonEpisodeString: String? {
        guard type != .movie else { return nil }

        guard let season = parentIndexNumber,
              let episode = indexNumber else {
            return nil
        }
        return "S\(season)E\(episode)"
    }
    
    var episodeOnlyString: String? {
        guard type != .movie else { return nil }
        guard let episode = indexNumber else { return nil }
        return "E\(episode)"
    }
}
