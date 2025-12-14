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

extension BaseItemDto {
    /// Converts an episode to its parent series BaseItemDto
    func toSeries() -> BaseItemDto? {
        guard type == .episode, let seriesID = seriesID else {
            return nil
        }
        
        var series = BaseItemDto()
        
        // Core identification
        series.id = seriesID
        series.type = .series
        
        // Name from series fields
        series.name = seriesName
        
        // Use parent backdrop if available (often the series backdrop)
        series.backdropImageTags = parentBackdropImageTags
        
        // Studio
        series.seriesStudio = seriesStudio
        series.studios = studios
        
        return series
    }
}
