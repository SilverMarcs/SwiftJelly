//
//  PlaybackStateManager.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 29/06/2025.
//

import Foundation
import VLCUI
import Combine

/// Manages playback state for media player
class PlaybackStateManager: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentSeconds: Int = 0
    @Published var totalSeconds: Int = 1
    @Published var isSeeking: Bool = false
    @Published var seekValue: Double = 0
    
    // MARK: - Public Methods
    
    /// Updates the current playback position
    func updatePosition(seconds: Int, totalDuration: Int) {
        currentSeconds = seconds
        totalSeconds = totalDuration
        
        if !isSeeking {
            seekValue = Double(seconds)
        }
    }
    
    /// Updates the playing state
    func updatePlayingState(_ playing: Bool) {
        isPlaying = playing
    }
    
    /// Starts seeking operation
    func startSeeking(to value: Double) {
        isSeeking = true
        seekValue = value
    }
    
    /// Ends seeking operation and returns the seek position in seconds
    func endSeeking() -> Int {
        isSeeking = false
        return Int(seekValue)
    }
    
    /// Gets the current position for display (either actual position or seek position)
    var displayPosition: Double {
        return isSeeking ? seekValue : Double(currentSeconds)
    }
    
    /// Gets the current position in seconds
    var currentPositionSeconds: Int {
        return isSeeking ? Int(seekValue) : currentSeconds
    }
    
    /// Calculates progress percentage (0.0 to 1.0)
    var progressPercentage: Double {
        guard totalSeconds > 0 else { return 0.0 }
        return Double(currentSeconds) / Double(totalSeconds)
    }
    
    /// Gets remaining time in seconds
    var remainingSeconds: Int {
        return max(0, totalSeconds - currentSeconds)
    }
}
