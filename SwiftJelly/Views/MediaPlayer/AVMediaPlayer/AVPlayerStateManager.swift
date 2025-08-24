import Foundation
import AVFoundation
import JellyfinAPI
import Combine

@Observable class AVPlayerStateManager {
    var player: AVPlayer
    
    @ObservationIgnored private let reporter: PlaybackReporterProtocol
    @ObservationIgnored private let mediaItem: MediaItem
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var lastReportedTimeControlStatus: AVPlayer.TimeControlStatus?
    
    init(mediaItem: MediaItem) {
        self.mediaItem = mediaItem
        
        // Initialize appropriate playback reporter based on media type
        switch mediaItem {
        case .jellyfin(let item):
            self.reporter = JellyfinPlaybackReporter(item: item)
        case .local(let file):
            self.reporter = LocalPlaybackReporter(file: file)
        }
        
        self.player = AVPlayer(url: mediaItem.url)
        setupPlayerObservation()
    }

    private func setupPlayerObservation() {
        // Clear existing observations
        cancellables.removeAll()
        
        // Observe timeControlStatus for play/pause state changes
        player.publisher(for: \.timeControlStatus)
            .removeDuplicates()
            .sink { [weak self] status in
                self?.handleTimeControlStatusChange(status)
            }
            .store(in: &cancellables)
    }
    
    private func handleTimeControlStatusChange(_ status: AVPlayer.TimeControlStatus) {
        // Avoid duplicate reports for the same status
        guard status != lastReportedTimeControlStatus else { return }
        lastReportedTimeControlStatus = status
        
        switch status {
        case .playing:
            if !reporter.hasStarted {
                reporter.reportStart(positionSeconds: currentPosition)
            } else {
                reporter.reportResume(positionSeconds: currentPosition)
            }
        case .paused:
            if reporter.hasStarted {
                reporter.reportPause(positionSeconds: currentPosition)
            }
        case .waitingToPlayAtSpecifiedRate:
            // Buffering state - we can ignore this for now
            break
        @unknown default:
            break
        }
    }
    
    func close() {
        // Report stop if not already stopped
        reporter.reportStop(positionSeconds: currentPosition)
        player.pause()
        cancellables.removeAll()
    }
    
    private var currentPosition: Int {
        guard let time = player.currentItem?.currentTime(), time.isValid else { return 0 }
        return Int(time.seconds)
    }
    
    deinit {
        cancellables.removeAll()
    }
}
