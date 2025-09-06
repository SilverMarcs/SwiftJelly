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
    
    #if os(macOS)
    // Store bookmark data for macOS security-scoped access
    private let bookmarkData: Data?
    
    init(url: URL) {
        self.url = url
        self.name = url.deletingPathExtension().lastPathComponent
        self.durationSeconds = nil
        
        // Create security-scoped bookmark
        do {
            self.bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        } catch {
            print("Failed to create bookmark for \(url): \(error)")
            self.bookmarkData = nil
        }
    }
    
    init(url: URL, name: String, durationSeconds: Int? = nil) {
        self.url = url
        self.name = name
        self.durationSeconds = durationSeconds
        
        // Create security-scoped bookmark
        do {
            self.bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        } catch {
            print("Failed to create bookmark for \(url): \(error)")
            self.bookmarkData = nil
        }
    }
    
    /// Create from bookmark data (for loading from persistence)
    init?(bookmarkData: Data) {
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            
            self.url = url
            self.name = url.deletingPathExtension().lastPathComponent
            self.bookmarkData = bookmarkData
            
            // Try to restore saved duration
            let durationKey = "localMedia_duration_\(url.absoluteString.hash)"
            let savedDuration = UserDefaults.standard.integer(forKey: durationKey)
            self.durationSeconds = savedDuration > 0 ? savedDuration : nil
            
            // Start accessing the security-scoped resource
            if !url.startAccessingSecurityScopedResource() {
                print("Failed to start accessing security-scoped resource")
                return nil
            }
        } catch {
            print("Failed to resolve bookmark: \(error)")
            return nil
        }
    }
    
    #else
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
    #endif
    
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
    
    #if os(macOS)
    /// Stop accessing the security-scoped resource when done
    func stopAccessingSecurityScopedResource() {
        url.stopAccessingSecurityScopedResource()
    }
    #endif
}
