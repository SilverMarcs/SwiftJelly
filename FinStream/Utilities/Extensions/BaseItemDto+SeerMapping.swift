//
//  BaseItemDto+SeerMapping.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation
import JellyfinAPI

extension BaseItemDto {
    init?(seerResult: SeerSearchResult) {
        guard let reference = seerResult.reference else { return nil }
        self.init(seerReference: reference, posterPath: seerResult.posterPath, backdropPath: seerResult.backdropPath)
        name = seerResult.displayTitle
        overview = seerResult.overview
        productionYear = SeerDateParser.year(from: seerResult.airDate)
        communityRating = seerResult.voteAverage.flatMap(Self.rating)
    }

    init(seerMovie movie: SeerMovieDetails) {
        self.init(seerReference: movie.reference, posterPath: movie.posterPath, backdropPath: movie.backdropPath)
        name = movie.title
        overview = movie.overview
        taglines = movie.tagline.map { [$0] }
        productionYear = SeerDateParser.year(from: movie.releaseDate)
        premiereDate = SeerDateParser.date(from: movie.releaseDate)
        runTimeTicks = movie.runtime.map { Self.ticks(minutes: $0) }
        communityRating = movie.voteAverage.flatMap(Self.rating)
        officialRating = movie.releases?.preferredCertification
        genres = movie.genres?.map(\.name)
        studios = movie.productionCompanies?.map { NameGuidPair(name: $0.name) }
        productionLocations = movie.productionCountries?.map(\.name)
    }

    init(seerShow show: SeerTVDetails) {
        self.init(seerReference: show.reference, posterPath: show.posterPath, backdropPath: show.backdropPath)
        name = show.name
        overview = show.overview
        taglines = show.tagline.map { [$0] }
        status = show.status
        productionYear = SeerDateParser.year(from: show.firstAirDate)
        premiereDate = SeerDateParser.date(from: show.firstAirDate)
        endDate = SeerDateParser.date(from: show.lastAirDate)
        communityRating = show.voteAverage.flatMap(Self.rating)
        officialRating = show.contentRatings?.preferredRating
        genres = show.genres?.map(\.name)
        studios = show.networks?.map { NameGuidPair(name: $0.name) }
        productionLocations = show.productionCountries?.map(\.name)
    }

    init(seerEpisode episode: SeerEpisode, showName: String?) {
        self.init()
        id = "\(SeerMediaReference.serverID)-episode-\(episode.id)"
        serverID = SeerMediaReference.serverID
        type = .episode
        name = episode.name
        overview = episode.overview
        seriesName = showName
        indexNumber = episode.episodeNumber
        parentIndexNumber = episode.seasonNumber
        premiereDate = SeerDateParser.date(from: episode.airDate)
        imageTags = episode.stillPath.map { [ImageType.primary.rawValue: $0] }
    }

    init(seerReference reference: SeerMediaReference, posterPath: String? = nil, backdropPath: String? = nil) {
        self.init()
        id = reference.itemID
        serverID = SeerMediaReference.serverID
        type = reference.mediaType == .movie ? .movie : .series
        imageTags = posterPath.map { [ImageType.primary.rawValue: $0] }
        backdropImageTags = backdropPath.map { [$0] }
    }

    private static func rating(_ voteAverage: Double) -> Float? {
        voteAverage > 0 ? Float(voteAverage) : nil
    }

    private static func ticks(minutes: Int) -> Int {
        minutes * 60 * 10_000_000
    }
}
