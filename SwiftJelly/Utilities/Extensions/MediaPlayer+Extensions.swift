//
//  MediaPlayer+Extensions.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 29/06/2025.
//

import Foundation

// MARK: - Position Tick Conversion Extensions
extension Int {
    /// Converts seconds to Jellyfin position ticks (1 second = 10,000,000 ticks)
    var toPositionTicks: Int64 {
        return Int64(self) * 10_000_000
    }
}

// MARK: - Double Extensions for Slider Values
extension Double {
    /// Converts slider value to position ticks, guarding against NaN/inf
    var toPositionTicks: Int64 {
        guard isFinite else { return 0 }
        return Int64(self) * 10_000_000
    }
}
