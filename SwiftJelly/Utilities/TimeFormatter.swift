//
//  TimeFormatter.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 24/08/2025.
//

import Foundation

extension Int {
    /// Formats seconds into a time string (MM:SS or HH:MM:SS)
    func timeString() -> String {
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

extension TimeInterval {
    /// Formats TimeInterval into a time string (MM:SS or HH:MM:SS)
    func timeString() -> String {
        Int(self).timeString()
    }
}
