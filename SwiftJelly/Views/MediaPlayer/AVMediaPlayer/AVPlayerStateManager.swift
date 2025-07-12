//
//  AVPlayerStateManager.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import Foundation
import AVFoundation
import JellyfinAPI

/// Simple state manager for AVPlayer with progress reporting
@Observable class AVPlayerStateManager {
    var isPlaying: Bool = false
    var currentSeconds: Int = 0
    @ObservationIgnored var totalSeconds: Int = 1
    
    @ObservationIgnored private let reporter: PlaybackReporter
    @ObservationIgnored private var timeObserverToken: Any?
    @ObservationIgnored private var player: AVPlayer?
    
    init(item: BaseItemDto) {
        self.reporter = PlaybackReporter(item: item)
    }
    
    deinit {
        removeTimeObserver()
        NotificationCenter.default.removeObserver(self)
    }
    
    func setPlayer(_ player: AVPlayer) {
        self.player = player
        setupTimeObserver()
        
        // Delay notifications setup to allow player item to load
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setupNotifications()
        }
    }
    
    private func setupTimeObserver() {
        guard let player = player else { return }
        
        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.updateCurrentTime(time)
        }
    }
    
    private func removeTimeObserver() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
    
    private func setupNotifications() {
        guard let player = player, let currentItem = player.currentItem else { return }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: currentItem
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFail),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: currentItem
        )
    }
    
    private func updateCurrentTime(_ time: CMTime) {
        // Validate time before converting
        guard time.isValid, !time.seconds.isNaN, !time.seconds.isInfinite else { return }
        
        let seconds = Int(time.seconds)
        currentSeconds = seconds
        
        if let duration = player?.currentItem?.duration, 
           duration.isValid, 
           !duration.seconds.isNaN, 
           !duration.seconds.isInfinite {
            totalSeconds = Int(duration.seconds)
        }
        
        // Check playing state
        let newIsPlaying = player?.rate ?? 0 > 0
        if newIsPlaying != isPlaying {
            isPlaying = newIsPlaying
            handlePlayingStateChange(newIsPlaying)
        }
    }
    
    private func handlePlayingStateChange(_ playing: Bool) {
        if playing && !reporter.hasStarted {
            reporter.reportStart(positionSeconds: currentSeconds)
        } else if reporter.hasStarted {
            if playing {
                reporter.reportResume(positionSeconds: currentSeconds)
            } else {
                reporter.reportPause(positionSeconds: currentSeconds)
            }
        }
    }
    
    @objc private func playerDidFinishPlaying() {
        stopPlayback()
    }
    
    @objc private func playerDidFail() {
        stopPlayback()
    }
    
    func stopPlayback() {
        reporter.reportStop(positionSeconds: currentSeconds)
        cleanup()
    }
    
    private func cleanup() {
        removeTimeObserver()
        NotificationCenter.default.removeObserver(self)
        player = nil
    }
}
