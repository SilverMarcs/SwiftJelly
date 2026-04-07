//
//  DiscoverFilters.swift
//  SwiftJelly
//

import Foundation

struct DiscoverFilters: Equatable {
    var language: String?
    var genre: TMDBGenre?
    var watchProvider: WatchProvider?
    var voteAverageGte: Double?
    var voteCountGte: Int?

    var isActive: Bool {
        language != nil || genre != nil || watchProvider != nil || voteAverageGte != nil || voteCountGte != nil
    }

    mutating func reset() {
        language = nil
        genre = nil
        watchProvider = nil
        voteAverageGte = nil
        voteCountGte = nil
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let language { items.append(URLQueryItem(name: "language", value: language)) }
        if let genre { items.append(URLQueryItem(name: "genre", value: String(genre.id))) }
        if let watchProvider { items.append(URLQueryItem(name: "watchProviders", value: String(watchProvider.id))) }
        if let voteAverageGte { items.append(URLQueryItem(name: "voteAverageGte", value: String(voteAverageGte))) }
        if let voteCountGte { items.append(URLQueryItem(name: "voteCountGte", value: String(voteCountGte))) }
        return items
    }
}

// MARK: - TMDB Genres

struct TMDBGenre: Identifiable, Equatable, Hashable {
    let id: Int
    let name: String
}

enum TMDBGenres {
    static let movie: [TMDBGenre] = [
        TMDBGenre(id: 28, name: "Action"),
        TMDBGenre(id: 12, name: "Adventure"),
        TMDBGenre(id: 16, name: "Animation"),
        TMDBGenre(id: 35, name: "Comedy"),
        TMDBGenre(id: 80, name: "Crime"),
        TMDBGenre(id: 99, name: "Documentary"),
        TMDBGenre(id: 18, name: "Drama"),
        TMDBGenre(id: 10751, name: "Family"),
        TMDBGenre(id: 14, name: "Fantasy"),
        TMDBGenre(id: 36, name: "History"),
        TMDBGenre(id: 27, name: "Horror"),
        TMDBGenre(id: 10402, name: "Music"),
        TMDBGenre(id: 9648, name: "Mystery"),
        TMDBGenre(id: 10749, name: "Romance"),
        TMDBGenre(id: 878, name: "Science Fiction"),
        TMDBGenre(id: 10770, name: "TV Movie"),
        TMDBGenre(id: 53, name: "Thriller"),
        TMDBGenre(id: 10752, name: "War"),
        TMDBGenre(id: 37, name: "Western"),
    ]

    static let tv: [TMDBGenre] = [
        TMDBGenre(id: 10759, name: "Action & Adventure"),
        TMDBGenre(id: 16, name: "Animation"),
        TMDBGenre(id: 35, name: "Comedy"),
        TMDBGenre(id: 80, name: "Crime"),
        TMDBGenre(id: 99, name: "Documentary"),
        TMDBGenre(id: 18, name: "Drama"),
        TMDBGenre(id: 10751, name: "Family"),
        TMDBGenre(id: 10762, name: "Kids"),
        TMDBGenre(id: 9648, name: "Mystery"),
        TMDBGenre(id: 10763, name: "News"),
        TMDBGenre(id: 10764, name: "Reality"),
        TMDBGenre(id: 10765, name: "Sci-Fi & Fantasy"),
        TMDBGenre(id: 10766, name: "Soap"),
        TMDBGenre(id: 10767, name: "Talk"),
        TMDBGenre(id: 10768, name: "War & Politics"),
        TMDBGenre(id: 37, name: "Western"),
    ]
}

// MARK: - Watch Providers

struct WatchProvider: Identifiable, Equatable, Hashable {
    let id: Int
    let name: String
}

enum WatchProviders {
    static let popular: [WatchProvider] = [
        WatchProvider(id: 8, name: "Netflix"),
        WatchProvider(id: 9, name: "Amazon Prime Video"),
        WatchProvider(id: 350, name: "Apple TV+"),
        WatchProvider(id: 337, name: "Disney+"),
        WatchProvider(id: 531, name: "Paramount+"),
        WatchProvider(id: 384, name: "HBO Max"),
        WatchProvider(id: 15, name: "Hulu"),
        WatchProvider(id: 386, name: "Peacock"),
        WatchProvider(id: 283, name: "Crunchyroll"),
        WatchProvider(id: 1899, name: "Max"),
    ]
}

// MARK: - Languages

struct DiscoverLanguage: Identifiable, Equatable, Hashable {
    let code: String
    let name: String
    var id: String { code }
}

enum DiscoverLanguages {
    static let all: [DiscoverLanguage] = [
        DiscoverLanguage(code: "en", name: "English"),
        DiscoverLanguage(code: "es", name: "Spanish"),
        DiscoverLanguage(code: "fr", name: "French"),
        DiscoverLanguage(code: "de", name: "German"),
        DiscoverLanguage(code: "it", name: "Italian"),
        DiscoverLanguage(code: "pt", name: "Portuguese"),
        DiscoverLanguage(code: "ja", name: "Japanese"),
        DiscoverLanguage(code: "ko", name: "Korean"),
        DiscoverLanguage(code: "zh", name: "Chinese"),
        DiscoverLanguage(code: "hi", name: "Hindi"),
        DiscoverLanguage(code: "ar", name: "Arabic"),
        DiscoverLanguage(code: "ru", name: "Russian"),
        DiscoverLanguage(code: "tr", name: "Turkish"),
        DiscoverLanguage(code: "bn", name: "Bengali"),
    ]
}

// MARK: - Vote Score Presets

enum VoteScorePreset: Double, CaseIterable, Identifiable {
    case five = 5.0
    case six = 6.0
    case seven = 7.0
    case eight = 8.0
    case nine = 9.0

    var id: Double { rawValue }

    var label: String {
        "\(Int(rawValue))+"
    }
}

// MARK: - Vote Count Presets

enum VoteCountPreset: Int, CaseIterable, Identifiable {
    case fifty = 50
    case hundred = 100
    case fiveHundred = 500
    case thousand = 1000
    case fiveThousand = 5000

    var id: Int { rawValue }

    var label: String {
        if rawValue >= 1000 {
            "\(rawValue / 1000)k+"
        } else {
            "\(rawValue)+"
        }
    }
}
