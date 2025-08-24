//
//  LocalMediaFile.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 25/08/2025.
//

import Foundation

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
