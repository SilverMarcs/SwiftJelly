import Foundation
import AVFoundation
import JellyfinAPI
import Combine

@Observable class AVPlayerStateManager {
    var player: AVPlayer?
    
    @ObservationIgnored private let reporter: JellyfinPlaybackReporter
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var lastReportedTimeControlStatus: AVPlayer.TimeControlStatus?

    init(item: BaseItemDto) {
        self.reporter = JellyfinPlaybackReporter(item: item)
        if let playbackURL = try? JFAPI.getPlaybackURL(for: item) {
            self.player = AVPlayer(url: playbackURL)
            setupPlayerObservation()
        }
    }

    private func setupPlayerObservation() {
        // Clear existing observations
        cancellables.removeAll()
        
        guard let player = player else { return }
        
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
    
    func stop() {
        player?.pause()
        reporter.reportStop(positionSeconds: currentPosition)
        player = nil
    }
    
    private var currentPosition: Int {
        guard let player = player, let time = player.currentItem?.currentTime(), time.isValid else { return 0 }
        return Int(time.seconds)
    }
    
    deinit {
        cancellables.removeAll()
    }
}
