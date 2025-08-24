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
            guard let durationSeconds = file.durationSeconds else { return nil }
            return TimeInterval(durationSeconds)
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
        case .local(let file):
            return file.savedPosition // Resume from saved position
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
    let durationSeconds: Int?
    
    init(url: URL) {
        self.url = url
        self.name = url.deletingPathExtension().lastPathComponent
        self.durationSeconds = nil
    }
    
    init(url: URL, name: String, durationSeconds: Int? = nil) {
        self.url = url
        self.name = name
        self.durationSeconds = durationSeconds
    }
    
    /// Get the saved playback position for this file
    var savedPosition: Int {
        let key = "localMedia_position_\(url.absoluteString.hash)"
        return UserDefaults.standard.integer(forKey: key)
    }
    
    /// Check if this file has been marked as completed
    var isCompleted: Bool {
        let key = "localMedia_completed_\(url.absoluteString.hash)"
        return UserDefaults.standard.bool(forKey: key)
    }
    
    /// Get progress percentage based on saved position and duration
    var progress: Double? {
        guard let durationSeconds = durationSeconds, durationSeconds > 0 else { return nil }
        return Double(savedPosition) / Double(durationSeconds)
    }
}
