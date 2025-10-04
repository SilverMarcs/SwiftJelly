//import Foundation
//import AVFoundation
//import JellyfinAPI
//import Combine
//
//@Observable class AVPlayerStateManager {
//    var player: AVPlayer
//    
//    @ObservationIgnored private let reporter: PlaybackReporterProtocol
//    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
//    @ObservationIgnored private var lastReportedTimeControlStatus: AVPlayer.TimeControlStatus?
//    
//    init() {
//        // Placeholder init since class is commented
//        self.reporter = LocalPlaybackReporter(file: URL(fileURLWithPath: ""))
//        self.player = AVPlayer()
//        setupPlayerObservation()
//    }
//
//    private func setupPlayerObservation() {
//        // Clear existing observations
//        cancellables.removeAll()
//        
//        // Observe timeControlStatus for play/pause state changes
//        player.publisher(for: \.timeControlStatus)
//            .removeDuplicates()
//            .sink { [weak self] status in
//                self?.handleTimeControlStatusChange(status)
//            }
//            .store(in: &cancellables)
//    }
//    
//    private func handleTimeControlStatusChange(_ status: AVPlayer.TimeControlStatus) {
//        // Avoid duplicate reports for the same status
//        guard status != lastReportedTimeControlStatus else { return }
//        lastReportedTimeControlStatus = status
//        
//        switch status {
//        case .playing:
//            if !reporter.hasStarted {
//                reporter.reportStart(positionSeconds: currentPosition)
//            } else {
//                reporter.reportResume(positionSeconds: currentPosition)
//            }
//        case .paused:
//            if reporter.hasStarted {
//                reporter.reportPause(positionSeconds: currentPosition)
//            }
//        case .waitingToPlayAtSpecifiedRate:
//            // Buffering state - we can ignore this for now
//            break
//        @unknown default:
//            break
//        }
//    }
//    
//    func close() {
//        // Report stop if not already stopped
//        reporter.reportStop(positionSeconds: currentPosition)
//        player.pause()
//        cancellables.removeAll()
//    }
//    
//    private var currentPosition: Int {
//        guard let time = player.currentItem?.currentTime(), time.isValid else { return 0 }
//        return Int(time.seconds)
//    }
//    
//    deinit {
//        cancellables.removeAll()
//    }
//}
