//
//  BaseItemDto+NowPlaying.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 14/07/2025.
//

import Foundation
import JellyfinAPI

extension BaseItemDto {
    var derivedNavigationTitle: String {
        if let seriesName = seriesName {
            var title = seriesName
            if let season = parentIndexNumber, let episode = indexNumber {
                title += " • S\(season)E\(episode)"
            }
            return title
        } else if let movieTitle = name {
            return movieTitle
        } else {
            return "Now Playing"
        }
    }
}
