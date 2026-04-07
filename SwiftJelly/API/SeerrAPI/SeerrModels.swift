//
//  SeerrModels.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 04/04/2026.
//

import Foundation

// MARK: - User

struct SeerrUser: Decodable {
    let id: Int
    let displayName: String?
    let email: String?
    let requestCount: Int?
    let avatar: String?
}

// MARK: - Media Status

enum SeerrMediaStatus: Int, Decodable {
    case unknown = 1
    case pending = 2
    case processing = 3
    case partiallyAvailable = 4
    case available = 5
    case deleted = 6

    var label: String {
        switch self {
        case .unknown: "Not Requested"
        case .pending: "Pending"
        case .processing: "Processing"
        case .partiallyAvailable: "Partially Available"
        case .available: "Available"
        case .deleted: "Deleted"
        }
    }
}

enum SeerrRequestStatus: Int, Decodable {
    case pending = 1
    case approved = 2
    case declined = 3

    var label: String {
        switch self {
        case .pending: "Pending"
        case .approved: "Approved"
        case .declined: "Declined"
        }
    }
}

// MARK: - Media Info

struct SeerrMediaInfo: Decodable {
    let id: Int?
    let tmdbId: Int?
    let status: Int?
    let requests: [SeerrMediaRequest]?

    var mediaStatus: SeerrMediaStatus {
        SeerrMediaStatus(rawValue: status ?? 1) ?? .unknown
    }
}

// MARK: - Media Request

struct SeerrMediaRequest: Decodable, Identifiable {
    let id: Int
    let status: Int
    let media: SeerrMediaInfo?
    let requestedBy: SeerrUser?
    let is4k: Bool?
    let createdAt: String?
    let updatedAt: String?

    var requestStatus: SeerrRequestStatus {
        SeerrRequestStatus(rawValue: status) ?? .pending
    }
}

// MARK: - Search / Discover Results

struct SeerrSearchResult: Decodable, Identifiable {
    let id: Int
    let mediaType: String

    var uniqueID: String { "\(mediaType)-\(id)" }
    let title: String?
    let name: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let mediaInfo: SeerrMediaInfo?

    var displayTitle: String { title ?? name ?? "" }
    var isMovie: Bool { mediaType == "movie" }
    var isTV: Bool { mediaType == "tv" }

    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }

    var backdropURL: URL? {
        guard let path = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w780\(path)")
    }

    var year: String? {
        let date = releaseDate ?? firstAirDate
        return date?.prefix(4).description
    }
}

// MARK: - Paginated Response

struct SeerrPaginatedResponse<T: Decodable>: Decodable {
    let page: Int
    let totalPages: Int
    let totalResults: Int
    let results: [T]
}

// MARK: - Request Count

struct SeerrRequestCount: Decodable {
    let total: Int
    let movie: Int
    let tv: Int
    let pending: Int
    let approved: Int
    let declined: Int
    let processing: Int
    let available: Int
}

// MARK: - Movie Details

struct SeerrMovieDetails: Decodable {
    let id: Int
    let title: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let runtime: Int?
    let voteAverage: Double?
    let mediaInfo: SeerrMediaInfo?

    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
}

// MARK: - TV Details

struct SeerrTVDetails: Decodable {
    let id: Int
    let name: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String?
    let numberOfSeasons: Int?
    let voteAverage: Double?
    let mediaInfo: SeerrMediaInfo?

    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
}

// MARK: - Request List Response

struct SeerrRequestListResponse: Decodable {
    let pageInfo: SeerrPageInfo
    let results: [SeerrMediaRequest]
}

struct SeerrPageInfo: Decodable {
    let page: Int?
    let pages: Int
    let results: Int
}
