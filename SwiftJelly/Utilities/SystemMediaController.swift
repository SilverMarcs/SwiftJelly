import Foundation
import MediaPlayer
import JellyfinAPI
import SwiftUI
#if !os(macOS)
import AVFoundation
#endif

public class SystemMediaController {
    static let shared = SystemMediaController()
    
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    private let remoteCommandCenter = MPRemoteCommandCenter.shared()
    
    private var playPauseHandler: (() -> Void)?
    private var nextHandler: (() -> Void)?
    private var previousHandler: (() -> Void)?
    private var seekHandler: ((Double) -> Void)?
    private var changePlaybackPositionHandler: ((Double) -> Void)?
    
    private init() {
        setupRemoteCommandHandlers()
        #if os(iOS)
        setupAudioSession()
        #endif
    }
    
    private func setupRemoteCommandHandlers() {
        // Play command
        remoteCommandCenter.playCommand.addTarget { [weak self] _ in
            self?.playPauseHandler?()
            return .success
        }
        
        // Pause command
        remoteCommandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.playPauseHandler?()
            return .success
        }
        
        // Toggle play/pause command
        remoteCommandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.playPauseHandler?()
            return .success
        }
        
        // Next track command
        remoteCommandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.nextHandler?()
            return .success
        }
        
        // Previous track command
        remoteCommandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.previousHandler?()
            return .success
        }
        
        // Seek commands
        remoteCommandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: 10)]
        remoteCommandCenter.skipForwardCommand.addTarget { [weak self] event in
            if let skipEvent = event as? MPSkipIntervalCommandEvent {
                self?.seekHandler?(skipEvent.interval)
            }
            return .success
        }
        
        remoteCommandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: 10)]
        remoteCommandCenter.skipBackwardCommand.addTarget { [weak self] event in
            if let skipEvent = event as? MPSkipIntervalCommandEvent {
                self?.seekHandler?(-skipEvent.interval)
            }
            return .success
        }
        
        // Change playback position command
        remoteCommandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let positionEvent = event as? MPChangePlaybackPositionCommandEvent {
                self?.changePlaybackPositionHandler?(positionEvent.positionTime)
            }
            return .success
        }
        
        // Enable the commands
        remoteCommandCenter.playCommand.isEnabled = true
        remoteCommandCenter.pauseCommand.isEnabled = true
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = true
        remoteCommandCenter.nextTrackCommand.isEnabled = false // Will be enabled when queue is available
        remoteCommandCenter.previousTrackCommand.isEnabled = false // Will be enabled when queue is available
        remoteCommandCenter.skipForwardCommand.isEnabled = true
        remoteCommandCenter.skipBackwardCommand.isEnabled = true
        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = true
    }
    
    #if !os(macOS)
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    #endif
    
    // MARK: - Public Methods
    
    public func setHandlers(
        playPause: @escaping () -> Void,
        next: (() -> Void)? = nil,
        previous: (() -> Void)? = nil,
        seek: @escaping (Double) -> Void,
        changePlaybackPosition: @escaping (Double) -> Void
    ) {
        self.playPauseHandler = playPause
        self.nextHandler = next
        self.previousHandler = previous
        self.seekHandler = seek
        self.changePlaybackPositionHandler = changePlaybackPosition
        
        // Enable/disable commands based on availability
        remoteCommandCenter.nextTrackCommand.isEnabled = next != nil
        remoteCommandCenter.previousTrackCommand.isEnabled = previous != nil
    }
    
    public func updateNowPlayingInfo(
        title: String,
        artist: String? = nil,
        albumTitle: String? = nil,
        artwork: MPMediaItemArtwork? = nil,
        duration: Double,
        currentTime: Double,
        playbackRate: Double = 1.0
    ) {
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: playbackRate,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.video.rawValue
        ]
        
        if let artist = artist {
            nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        }
        
        if let albumTitle = albumTitle {
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = albumTitle
        }
        
        if let artwork = artwork {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
    
    public func updatePlaybackState(isPlaying: Bool, currentTime: Double) {
        var currentInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [:]
        currentInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        currentInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        nowPlayingInfoCenter.nowPlayingInfo = currentInfo
    }
    
    public func clearNowPlayingInfo() {
        nowPlayingInfoCenter.nowPlayingInfo = nil
    }
    
    #if os(macOS)
    public func createArtwork(from image: NSImage) -> MPMediaItemArtwork {
        return MPMediaItemArtwork(boundsSize: image.size) { _ in
            return image
        }
    }
    #else
    public func createArtwork(from image: UIImage) -> MPMediaItemArtwork {
        return MPMediaItemArtwork(boundsSize: image.size) { _ in
            return image
        }
    }
    #endif
}
