import Foundation

@Observable class PlaybackStateManager {
    var isPlaying: Bool = false
    var currentSeconds: Int = 0
    var totalDuration: Int = 0
    
    var currentProgress: Double {
        guard totalDuration > 0 else { return 0 }
        return Double(currentSeconds) / Double(totalDuration)
    }
    
    func updatePlayingState(_ playing: Bool) {
        isPlaying = playing
    }
    
    func updatePosition(seconds: Int, totalDuration: Int) {
        self.currentSeconds = seconds
        self.totalDuration = totalDuration
    }
}
