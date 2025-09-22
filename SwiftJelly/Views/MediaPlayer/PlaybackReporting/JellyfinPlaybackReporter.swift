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
    private var hasSentStart = false

    // Throttling by media time only
    private var lastReportedSeconds: Int? = nil
    private var lastTickSeconds: Int? = nil

    private let progressEverySeconds = 10
    private let seekJumpThresholdSeconds = 3

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
                self.lastTickSeconds = positionSeconds
            } catch {
                print("Failed to send start report: \(error)")
            }
        }
    }

    func reportProgress(positionSeconds: Int, isPaused: Bool) {
        guard hasSentStart else {
            reportStart(positionSeconds: positionSeconds)
        }

        // Always update lastTickSeconds at the end
        defer { self.lastTickSeconds = positionSeconds }

        // Skip periodic sends while paused (you already send on pause/resume)
        if isPaused {
            return
        }

        let lastTick = lastTickSeconds
        let lastSent = lastReportedSeconds

        // 1) Seek/jump detection (tick-to-tick jump)
        if let lastTick, abs(positionSeconds - lastTick) >= seekJumpThresholdSeconds {
            sendProgress(positionSeconds: positionSeconds, isPaused: false, force: true)
            return
        }

        // 2) Periodic by media-time since last report
        if let lastSent, positionSeconds - lastSent >= progressEverySeconds {
            sendProgress(positionSeconds: positionSeconds, isPaused: false, force: false)
            return
        }

        // 3) If nothing sent yet after start, send first tick
        if lastSent == nil {
            sendProgress(positionSeconds: positionSeconds, isPaused: false, force: false)
        }
    }

    func reportStop(positionSeconds: Int) {
        guard hasSentStart else { return }
        // Best-effort final update then stop
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

    private func sendProgress(positionSeconds: Int, isPaused: Bool, force: Bool) {
        Task {
            do {
                try await JFAPI.reportPlaybackProgress(
                    for: item,
                    positionTicks: positionSeconds.toPositionTicks,
                    isPaused: isPaused,
                    playSessionID: playSessionID
                )
                self.lastReportedSeconds = positionSeconds
            } catch {
                print("Failed to send progress report: \(error)")
                // On error, keep lastReportedSeconds unchanged so we can retry soon
            }
        }
    }
}
