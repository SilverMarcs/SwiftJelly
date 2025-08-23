//
//  MediaItem.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 23/08/2025.
//

import Foundation
import JellyfinAPI

/// Universal media item that can represent both Jellyfin items and local files
enum MediaItem: Codable, Hashable {
    case jellyfin(BaseItemDto)
    case local(LocalMediaFile)
    
    var name: String? {
        switch self {
        case .jellyfin(let item):
            return item.name
        case .local(let file):
            return file.name
        }
    }
    
    var duration: TimeInterval? {
        switch self {
        case .jellyfin(let item):
            guard let ticks = item.runTimeTicks else { return nil }
            return Double(ticks) / 10_000_000
        case .local(let file):
            return file.duration
        }
    }
    
    var url: URL? {
        switch self {
        case .jellyfin(let item):
            return try? JFAPI.getPlaybackURL(for: item)
        case .local(let file):
            return file.url
        }
    }
    
    var startTimeSeconds: Int {
        switch self {
        case .jellyfin(let item):
            return JFAPI.getStartTimeSeconds(for: item)
        case .local:
            return 0 // Local files start from beginning
        }
    }
    
    var isJellyfin: Bool {
        if case .jellyfin = self { return true }
        return false
    }
    
    var isLocal: Bool {
        if case .local = self { return true }
        return false
    }
    
    /// Get BaseItemDto if this is a Jellyfin item
    var jellyfinItem: BaseItemDto? {
        if case .jellyfin(let item) = self { return item }
        return nil
    }
    
    /// Get LocalMediaFile if this is a local file
    var localFile: LocalMediaFile? {
        if case .local(let file) = self { return file }
        return nil
    }
}

/// Represents a local media file
struct LocalMediaFile: Codable, Hashable {
    let url: URL
    let name: String
    let duration: TimeInterval?
    
    init(url: URL) {
        self.url = url
        self.name = url.deletingPathExtension().lastPathComponent
        self.duration = nil // TODO: Could be populated using AVAsset if needed
    }
    
    init(url: URL, name: String, duration: TimeInterval? = nil) {
        self.url = url
        self.name = name
        self.duration = duration
    }
}
