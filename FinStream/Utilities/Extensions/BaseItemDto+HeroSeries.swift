//
//  BaseItemDto+HeroSeries.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation
import JellyfinAPI

extension BaseItemDto {
    var heroSeriesItem: BaseItemDto {
        var series = BaseItemDto()
        series.id = parentLogoItemID ?? seriesID
        series.type = .series
        series.name = seriesName ?? name
        series.imageTags = parentLogoImageTag.map { [ImageType.logo.rawValue: $0] }
        series.genres = (genres?.isEmpty == false) ? genres : seriesName.map { [$0] }
        return series
    }
}
