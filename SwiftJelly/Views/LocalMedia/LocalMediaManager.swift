//
//  LocalMediaManager.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 23/08/2025.
//

import Foundation
import AVFoundation

@Observable
class LocalMediaManager {
    static let shared = LocalMediaManager()
    
    private(set) var recentFiles: [LocalMediaFile] = []
    private let maxRecentFiles = 10
    
    private init() {
        loadRecentFiles()
    }
    
    /// Add a file to recent files list
    func addRecentFile(_ file: LocalMediaFile) {
        // Remove if already exists
        recentFiles.removeAll { $0.url == file.url }
        
        // Add to beginning
        recentFiles.insert(file, at: 0)
        
        // Limit size
        if recentFiles.count > maxRecentFiles {
            recentFiles = Array(recentFiles.prefix(maxRecentFiles))
        }
        
        saveRecentFiles()
    }
    
    /// Remove a file from recent files list
    func removeRecentFile(_ file: LocalMediaFile) {
        recentFiles.removeAll { $0.url == file.url }
        saveRecentFiles()
    }
    
    /// Get enhanced metadata for a local file
    func getEnhancedMetadata(for file: LocalMediaFile) async -> LocalMediaFile {
        guard file.duration == nil else { return file }
        
        do {
            let asset = AVURLAsset(url: file.url)
            let duration = try await asset.load(.duration)
            let durationSeconds = CMTimeGetSeconds(duration)
            
            return LocalMediaFile(
                url: file.url,
                name: file.name,
                duration: durationSeconds.isFinite ? durationSeconds : nil
            )
        } catch {
            print("Failed to load metadata for \(file.name): \(error)")
            return file
        }
    }
    
    /// Check if URL is a supported media file
    static func isSupportedMediaFile(_ url: URL) -> Bool {
        let supportedExtensions = [
            "mp4", "mov", "m4v", "avi", "mkv", "wmv", "flv", "webm",
            "mp3", "aac", "wav", "flac", "ogg", "m4a", "wma",
            "ts", "mts", "m2ts", "vob", "3gp", "f4v"
        ]
        
        let fileExtension = url.pathExtension.lowercased()
        return supportedExtensions.contains(fileExtension)
    }
    
    /// Clear playback data for a specific file
    func clearPlaybackData(for file: LocalMediaFile) {
        let positionKey = "localMedia_position_\(file.url.absoluteString.hash)"
        let completedKey = "localMedia_completed_\(file.url.absoluteString.hash)"
        
        UserDefaults.standard.removeObject(forKey: positionKey)
        UserDefaults.standard.removeObject(forKey: completedKey)
    }
    
    /// Clear all local media playback data
    func clearAllPlaybackData() {
        for file in recentFiles {
            clearPlaybackData(for: file)
        }
    }
    
    /// Get recently played files (files with saved progress)
    func getRecentlyPlayedFiles() -> [LocalMediaFile] {
        return recentFiles.filter { $0.savedPosition > 0 }
    }
    
    // MARK: - Persistence
    
    private func loadRecentFiles() {
        guard let data = UserDefaults.standard.data(forKey: "recentMediaFiles"),
              let urls = try? JSONDecoder().decode([URL].self, from: data) else {
            return
        }
        
        recentFiles = urls.compactMap { url in
            // Check if file still exists
            guard url.isFileURL, FileManager.default.fileExists(atPath: url.path) else {
                return nil
            }
            return LocalMediaFile(url: url)
        }
    }
    
    private func saveRecentFiles() {
        let urls = recentFiles.map { $0.url }
        if let data = try? JSONEncoder().encode(urls) {
            UserDefaults.standard.set(data, forKey: "recentMediaFiles")
        }
    }
}
