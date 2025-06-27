//
//  MediaItem.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import Foundation

struct MediaItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String?
    let type: MediaType?
    let serverId: String?
    
    // Basic Info
    let overview: String?
    let originalTitle: String?
    let seriesName: String?
    let album: String?
    
    // Time Related
    let runTimeTicks: Int64?
    let premiereDate: Date?
    let productionYear: Int?
    
    // Episode/Season Info
    let indexNumber: Int? // Episode number
    let parentIndexNumber: Int? // Season number
    let seasonId: String?
    let seriesId: String?
    
    // User Data
    let userData: UserData?
    
    // Images
    let imageTags: [String: String]?
    let backdropImageTags: [String]?
    let screenshotImageTags: [String]?
    let imageBlurHashes: [String: [String: String]]?
    
    // Media Streams
    let mediaStreams: [MediaStream]?
    
    // Location
    let locationType: String?
    
    // External Info
    let externalUrls: [ExternalUrl]?
    let criticRating: Double?
    let communityRating: Double?
    let genres: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case type = "Type"
        case serverId = "ServerId"
        case overview = "Overview"
        case originalTitle = "OriginalTitle"
        case seriesName = "SeriesName"
        case album = "Album"
        case runTimeTicks = "RunTimeTicks"
        case premiereDate = "PremiereDate"
        case productionYear = "ProductionYear"
        case indexNumber = "IndexNumber"
        case parentIndexNumber = "ParentIndexNumber"
        case seasonId = "SeasonId"
        case seriesId = "SeriesId"
        case userData = "UserData"
        case imageTags = "ImageTags"
        case backdropImageTags = "BackdropImageTags"
        case screenshotImageTags = "ScreenshotImageTags"
        case imageBlurHashes = "ImageBlurHashes"
        case mediaStreams = "MediaStreams"
        case locationType = "LocationType"
        case externalUrls = "ExternalUrls"
        case criticRating = "CriticRating"
        case communityRating = "CommunityRating"
        case genres = "Genres"
    }
    
    var displayTitle: String {
        name ?? "Unknown"
    }
    
    var seasonEpisodeLabel: String? {
        guard let seasonNo = parentIndexNumber, let episodeNo = indexNumber else { return nil }
        return "S\(seasonNo)E\(episodeNo)"
    }
    
    var runTimeSeconds: Int {
        Int((runTimeTicks ?? 0) / 10_000_000)
    }
    
    var startTimeSeconds: Int {
        Int((userData?.playbackPositionTicks ?? 0) / 10_000_000)
    }
    
    var progressPercentage: Double {
        guard let userData = userData,
              let playbackPositionTicks = userData.playbackPositionTicks,
              let runTimeTicks = runTimeTicks,
              runTimeTicks > 0 else { return 0 }
        return Double(playbackPositionTicks) / Double(runTimeTicks)
    }
    
    var progressLabel: String? {
        guard let userData = userData,
              let playbackPositionTicks = userData.playbackPositionTicks,
              let runTimeTicks = runTimeTicks,
              playbackPositionTicks > 0,
              runTimeTicks > 0 else { return nil }
        
        let remainingSeconds = (runTimeTicks - playbackPositionTicks) / 10_000_000
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        
        return formatter.string(from: TimeInterval(remainingSeconds))
    }
    
    var parentTitle: String? {
        switch type {
        case .audio:
            return album
        case .episode:
            return seriesName
        default:
            return nil
        }
    }
    
    var premiereDateYear: String? {
        guard let premiereDate = premiereDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: premiereDate)
    }
    
    func playbackURL(for server: Server, user: User, additionalParams: [String: String] = [:]) -> URL? {
        guard let token = user.accessToken else { return nil }
        var components = URLComponents(url: server.url, resolvingAgainstBaseURL: false)
        components?.path += "/Videos/\(id)/stream"
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "static", value: "true"),
            URLQueryItem(name: "api_key", value: token)
        ]
        for (k, v) in additionalParams { queryItems.append(URLQueryItem(name: k, value: v)) }
        components?.queryItems = queryItems
        return components?.url
    }
}

enum MediaType: String, Codable, CaseIterable {
    case movie = "Movie"
    case episode = "Episode"
    case series = "Series"
    case season = "Season"
    case audio = "Audio"
    case musicAlbum = "MusicAlbum"
    case musicArtist = "MusicArtist"
    case folder = "Folder"
    case collectionFolder = "CollectionFolder"
    case playlist = "Playlist"
    case boxSet = "BoxSet"
    case book = "Book"
    case photo = "Photo"
    case video = "Video"
    case program = "Program"
    case channel = "Channel"
    case livetv = "LiveTv"
    case recording = "Recording"
    case timer = "Timer"
    case seriesTimer = "SeriesTimer"
}

struct UserData: Codable, Hashable {
    let playbackPositionTicks: Int64?
    let playCount: Int?
    let isFavorite: Bool?
    let played: Bool?
    let playedPercentage: Double?
    let lastPlayedDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case playbackPositionTicks = "PlaybackPositionTicks"
        case playCount = "PlayCount"
        case isFavorite = "IsFavorite"
        case played = "Played"
        case playedPercentage = "PlayedPercentage"
        case lastPlayedDate = "LastPlayedDate"
    }
}

struct MediaStream: Codable, Hashable {
    let type: StreamType
    let codec: String?
    let language: String?
    let displayTitle: String?
    let index: Int?
    let isDefault: Bool?
    
    enum StreamType: String, Codable {
        case video = "Video"
        case audio = "Audio"
        case subtitle = "Subtitle"
    }
}

struct ExternalUrl: Codable, Hashable {
    let name: String?
    let url: String?
}

// Image Types available for media items
enum ImageType: String, CaseIterable {
    case primary = "Primary"
    case art = "Art"
    case backdrop = "Backdrop"
    case banner = "Banner"
    case logo = "Logo"
    case thumb = "Thumb"
    case disc = "Disc"
    case box = "Box"
    case screenshot = "Screenshot"
    case menu = "Menu"
    case chapter = "Chapter"
    case boxRear = "BoxRear"
    case profile = "Profile"
}
