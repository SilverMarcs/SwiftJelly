import Foundation
import JellyfinAPI

@Observable class PlaybackSessionManager {
    @ObservationIgnored private let item: BaseItemDto
    @ObservationIgnored private let playbackReporter: PlaybackReporter
    
    var hasSentStart: Bool = false
    
    init(item: BaseItemDto) {
        self.item = item
        self.playbackReporter = PlaybackReporter(item: item)
    }
    
    func startPlayback(at seconds: Int) {
        guard !hasSentStart else { return }
        playbackReporter.reportStart(positionSeconds: seconds)
        hasSentStart = true
    }
    
    func pausePlayback(at seconds: Int) {
        guard hasSentStart else { return }
        playbackReporter.reportPause(positionSeconds: seconds)
    }
    
    func resumePlayback(at seconds: Int) {
        guard hasSentStart else { return }
        playbackReporter.reportResume(positionSeconds: seconds)
    }
    
    func stopPlayback(at seconds: Int) {
        guard hasSentStart else { return }
        playbackReporter.reportStop(positionSeconds: seconds)
    }
}
