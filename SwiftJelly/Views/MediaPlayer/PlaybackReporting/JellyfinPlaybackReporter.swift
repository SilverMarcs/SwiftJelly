//
//  JellyfinPlaybackReporter.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 24/08/2025.
//

import Foundation
import JellyfinAPI

class JellyfinPlaybackReporter: PlaybackReporterProtocol {
    let playSessionID: String
    private let item: BaseItemDto
    private var hasSentStart: Bool = false
    
    // Throttling state
    private var lastReportedSeconds: Int? = nil
    private var lastReportAt: Date? = nil
    private let progressInterval: TimeInterval = 10 // seconds
    private let seekImmediateThreshold: Int = 3     // seconds; send immediately if position jumps by >= 3s

    var hasStarted: Bool { hasSentStart }
    
    init(item: BaseItemDto) {
        self.item = item
        self.playSessionID = JFAPI.generatePlaySessionID()
    }
    
    func reportStart(positionSeconds: Int) {
        guard !hasSentStart else { return }
        hasSentStart = true
        
        Task {
            do {
                try await JFAPI.reportPlaybackStart(
                    for: item,
                    positionTicks: positionSeconds.toPositionTicks,
                    playSessionID: playSessionID
                )
                self.lastReportedSeconds = positionSeconds
                self.lastReportAt = Date()
            } catch {
                print("Failed to send start report: \(error)")
            }
        }
    }
    
    func reportPause(positionSeconds: Int) {
        guard hasSentStart else { return }
        // Send immediately on pause
        sendProgress(positionSeconds: positionSeconds, isPaused: true, force: true)
    }
    
    func reportResume(positionSeconds: Int) {
        guard hasSentStart else { return }
        // Send immediately on resume
        sendProgress(positionSeconds: positionSeconds, isPaused: false, force: true)
    }
    
    func reportProgress(positionSeconds: Int, isPaused: Bool) {
        guard hasSentStart else { return }
        
        // If paused, we can either skip periodic reports or send at a slower rate.
        // Here we only send immediately when pausing, not while paused.
        if isPaused {
            return
        }
        
        let now = Date()
        let lastPos = lastReportedSeconds
        let lastAt = lastReportAt
        
        // Immediate send on seek-like jumps (forward or backward)
        if let last = lastPos, abs(positionSeconds - last) >= seekImmediateThreshold {
            sendProgress(positionSeconds: positionSeconds, isPaused: false, force: true)
            return
        }
        
        // Throttle to every 10 seconds of wall time OR position growth
        let elapsedTimeOK = lastAt.map { now.timeIntervalSince($0) >= progressInterval } ?? true
        let elapsedPosOK = lastPos.map { positionSeconds - $0 >= Int(progressInterval) } ?? true
        
        if elapsedTimeOK || elapsedPosOK {
            sendProgress(positionSeconds: positionSeconds, isPaused: false, force: false)
        }
    }
    
    func reportStop(positionSeconds: Int) {
        guard hasSentStart else { return }
        // Best effort: send a final progress, then stop
        sendProgress(positionSeconds: positionSeconds, isPaused: true, force: true)
        
        Task {
            do {
                try await JFAPI.reportPlaybackStopped(
                    for: item,
                    positionTicks: positionSeconds.toPositionTicks,
                    playSessionID: playSessionID
                )
            } catch {
                print("Failed to send stop report: \(error)")
            }
        }
    }
    
    // MARK: - Private
    
    private func sendProgress(positionSeconds: Int, isPaused: Bool, force: Bool) {
        Task {
            do {
                try await JFAPI.reportPlaybackProgress(
                    for: item,
                    positionTicks: positionSeconds.toPositionTicks,
                    isPaused: isPaused,
                    playSessionID: playSessionID
                )
                // Update throttling state only on success
                self.lastReportedSeconds = positionSeconds
                self.lastReportAt = Date()
            } catch {
                // On error, do not update throttling so a later call can retry
                print("Failed to send progress report: \(error)")
                if force {
                    // Optional: slight backoff if a forced event failed
                    // try? await Task.sleep(nanoseconds: 300_000_000)
                }
            }
        }
    }
}
