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
    private(set) var recentFiles: [LocalMediaFile] = []
    private let maxRecentFiles = 10
    
    init() {
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

    /// Replace or add a recent file and persist changes
    func updateRecentFile(_ file: LocalMediaFile) {
        recentFiles.removeAll { $0.url == file.url }
        recentFiles.insert(file, at: 0)

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
        guard file.durationSeconds == nil else { return file }
        
        do {
            let asset = AVURLAsset(url: file.url)
            let duration = try await asset.load(.duration)
            let durationSeconds = CMTimeGetSeconds(duration)
            
            return LocalMediaFile(
                url: file.url,
                name: file.name,
                durationSeconds: durationSeconds.isFinite ? Int(durationSeconds) : nil
            )
        } catch {
            print("Failed to load metadata for \(file.name): \(error)")
            return file
        }
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
    
    // MARK: - Persistence
    
    func loadRecentFiles() {
        guard let data = UserDefaults.standard.data(forKey: "recentMediaFiles"),
              let files = try? JSONDecoder().decode([LocalMediaFile].self, from: data) else {
            return
        }

        recentFiles = files.compactMap { file in
            // Check if file still exists
            guard file.url.isFileURL, FileManager.default.fileExists(atPath: file.url.path) else {
                return nil
            }
            return file
        }
    }
    
    private func saveRecentFiles() {
        if let data = try? JSONEncoder().encode(recentFiles) {
            UserDefaults.standard.set(data, forKey: "recentMediaFiles")
        }
    }
}
