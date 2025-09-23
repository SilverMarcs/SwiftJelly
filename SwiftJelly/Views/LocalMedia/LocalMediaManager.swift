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
        saveFileDuration(file)
    }

    /// Replace or add a recent file and persist changes
    func updateRecentFile(_ file: LocalMediaFile) {
        recentFiles.removeAll { $0.url == file.url }
        recentFiles.insert(file, at: 0)

        if recentFiles.count > maxRecentFiles {
            recentFiles = Array(recentFiles.prefix(maxRecentFiles))
        }

        saveRecentFiles()
        saveFileDuration(file)
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
    
    /// Save the duration for a specific file
    private func saveFileDuration(_ file: LocalMediaFile) {
        if let duration = file.durationSeconds {
            let durationKey = "localMedia_duration_\(file.url.absoluteString.hash)"
            UserDefaults.standard.set(duration, forKey: durationKey)
        }
    }
    
    // MARK: - Persistence
    
    func loadRecentFiles() {
        guard let data = UserDefaults.standard.data(forKey: "recentMediaFiles"),
              let bookmarkDatas = try? JSONDecoder().decode([Data].self, from: data) else {
            return
        }

        recentFiles = bookmarkDatas.compactMap { bookmarkData in
            return LocalMediaFile(bookmarkData: bookmarkData)
        }
    }
    
    private func saveRecentFiles() {
        let bookmarkDatas = recentFiles.compactMap { file -> Data? in
            do {
                return try file.url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            } catch {
                print("Failed to create bookmark for saving: \(error)")
                return nil
            }
        }
        
        if let data = try? JSONEncoder().encode(bookmarkDatas) {
            UserDefaults.standard.set(data, forKey: "recentMediaFiles")
        }
    }
}
