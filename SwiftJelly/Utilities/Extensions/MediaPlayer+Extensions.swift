//
//  MediaPlayer+Extensions.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 29/06/2025.
//

import Foundation

// MARK: - Time Formatting Extensions
extension Int {
    /// Formats seconds into a human-readable time string (MM:SS or H:MM:SS)
    var formattedTime: String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = self % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Position Tick Conversion Extensions
extension Int {
    /// Converts seconds to Jellyfin position ticks (1 second = 10,000,000 ticks)
    var toPositionTicks: Int64 {
        return Int64(self) * 10_000_000
    }
}

extension Int64 {
    /// Converts Jellyfin position ticks to seconds (1 second = 10,000,000 ticks)
    var toSeconds: Int {
        return Int(self / 10_000_000)
    }
}

// MARK: - Double Extensions for Slider Values
extension Double {
    /// Converts slider value to position ticks
    var toPositionTicks: Int64 {
        return Int64(self) * 10_000_000
    }
}
