//
//  PlaybackReporterProtocol.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 24/08/2025.
//

import Foundation

/// Protocol for handling playback session reporting
protocol PlaybackReporterProtocol {
    var hasStarted: Bool { get }
    
    /// Reports the start of playback
    func reportStart(positionSeconds: Int)
    
    /// Reports playback pause
    func reportPause(positionSeconds: Int)
    
    /// Reports playback resume
    func reportResume(positionSeconds: Int)
    
    /// Reports playback progress (periodic updates)
    func reportProgress(positionSeconds: Int, isPaused: Bool)
    
    /// Reports playback stop
    func reportStop(positionSeconds: Int)
}
