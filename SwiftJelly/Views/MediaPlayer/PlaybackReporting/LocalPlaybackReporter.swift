//
//  LocalPlaybackReporter.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 24/08/2025.
//

import Foundation

/// Handles playback position persistence for local media files
class LocalPlaybackReporter: PlaybackReporterProtocol {
    private let file: LocalMediaFile
    private let userDefaults = UserDefaults.standard
    var hasStarted: Bool = false
    
    init(file: LocalMediaFile) {
        self.file = file
    }
    
    /// Reports the start of playback and loads any existing position
    func reportStart(positionSeconds: Int) {
        savePlaybackPosition(positionSeconds)
    }
    
    /// Reports playback pause and saves position
    func reportPause(positionSeconds: Int) {
        savePlaybackPosition(positionSeconds)
    }
    
    /// Reports playback resume and saves position
    func reportResume(positionSeconds: Int) {
        savePlaybackPosition(positionSeconds)
    }
    
    /// Reports playback progress and periodically saves position
    func reportProgress(positionSeconds: Int, isPaused: Bool) {
        // Save position every 10 seconds to avoid excessive writes
        if positionSeconds % 10 == 0 {
            savePlaybackPosition(positionSeconds)
        }
    }
    
    /// Reports playback stop and saves final position
    func reportStop(positionSeconds: Int) {
        // If we're near the end (within last 5% of duration), mark as completed
        if let durationSeconds = file.durationSeconds {
            let progressPercent = Double(positionSeconds) / Double(durationSeconds)
            if progressPercent >= 0.95 {
                markAsCompleted()
            } else {
                savePlaybackPosition(positionSeconds)
            }
        } else {
            savePlaybackPosition(positionSeconds)
        }
    }
    
    // MARK: - Private Methods
    
    private func savePlaybackPosition(_ seconds: Int) {
        let key = playbackPositionKey
        userDefaults.set(seconds, forKey: key)
    }
    
    private func markAsCompleted() {
        let positionKey = playbackPositionKey
        let completedKey = playbackCompletedKey
        
        // Remove position (start from beginning next time)
        userDefaults.removeObject(forKey: positionKey)
        
        // Mark as completed
        userDefaults.set(true, forKey: completedKey)
    }
    
    private var playbackPositionKey: String {
        "localMedia_position_\(file.url.absoluteString.hash)"
    }
    
    private var playbackCompletedKey: String {
        "localMedia_completed_\(file.url.absoluteString.hash)"
    }
    
    // MARK: - Public Helpers
    
    /// Get the saved playback position for this file
    func getSavedPosition() -> Int {
        let key = playbackPositionKey
        return userDefaults.integer(forKey: key)
    }
    
    /// Check if this file has been marked as completed
    func isCompleted() -> Bool {
        let key = playbackCompletedKey
        return userDefaults.bool(forKey: key)
    }
    
    /// Clear playback data for this file
    func clearPlaybackData() {
        userDefaults.removeObject(forKey: playbackPositionKey)
        userDefaults.removeObject(forKey: playbackCompletedKey)
    }
}
