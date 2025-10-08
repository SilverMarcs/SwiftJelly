import Foundation
import JellyfinAPI

extension BaseItemDto {
    /// Returns the playback progress as a value between 0.0 and 1.0, or nil if not available.
    var playbackProgress: Double? {
        guard let ticks = userData?.playbackPositionTicks, let runtime = runTimeTicks, runtime > 0 else { return nil }
        let percent = Double(ticks) / Double(runtime)
        return percent > 1 ? 1 : percent
    }
    
    /// Returns the remaining time as a formatted string, or nil if not available or already finished.
    var timeRemainingString: String? {
        guard let ticks = userData?.playbackPositionTicks, let runtime = runTimeTicks, runtime > 0, ticks < runtime else { return nil }
        let seconds = (runtime - ticks) / 10_000_000
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval(seconds))
    }
    
    /// Returns the total duration as a formatted string, or nil if not available.
    var totalDurationString: String? {
        guard let runtime = runTimeTicks else { return nil }
        let seconds = runtime / 10_000_000
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval(seconds))
    }
    
    /// Returns the start time in seconds for playback based on saved position
    var startTimeSeconds: Int {
        guard let ticks = userData?.playbackPositionTicks else { return 0 }
        return Int(ticks / 10_000_000)
    }
}

extension BaseItemDto: @unchecked @retroactive Sendable {}
