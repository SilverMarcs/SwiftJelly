//
//  SeerRatings.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

struct SeerReleases: Decodable, Hashable {
    let results: [Region]

    struct Region: Decodable, Hashable {
        let region: String
        let releaseDates: [ReleaseDate]

        enum CodingKeys: String, CodingKey {
            case region = "iso_3166_1"
            case releaseDates = "release_dates"
        }
    }

    struct ReleaseDate: Decodable, Hashable {
        let certification: String?
    }

    var preferredCertification: String? {
        certification(for: SeerRegion.preferred) ?? certification(for: SeerRegion.fallback)
    }

    private func certification(for region: String) -> String? {
        results
            .first { $0.region == region }?
            .releaseDates
            .compactMap(\.certification)
            .first { !$0.isEmpty }
    }
}

struct SeerContentRatings: Decodable, Hashable {
    let results: [Rating]

    struct Rating: Decodable, Hashable {
        let region: String
        let rating: String

        enum CodingKeys: String, CodingKey {
            case region = "iso_3166_1"
            case rating
        }
    }

    var preferredRating: String? {
        let ratings = results.filter { !$0.rating.isEmpty }
        return ratings.first { $0.region == SeerRegion.preferred }?.rating
            ?? ratings.first { $0.region == SeerRegion.fallback }?.rating
    }
}

enum SeerRegion {
    static let fallback = "US"

    static var preferred: String {
        Locale.current.region?.identifier ?? fallback
    }
}
