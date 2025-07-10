import SwiftUI
import JellyfinAPI

struct ShowPlayButton: View {
    let show: BaseItemDto
    let episodes: [BaseItemDto]

    private var nextEpisode: BaseItemDto? {
        // Find the latest episode with progress
        let sorted = episodes.sorted { (a, b) in
            let aTicks = a.userData?.playbackPositionTicks ?? 0
            let bTicks = b.userData?.playbackPositionTicks ?? 0
            if aTicks > 0 && bTicks > 0 {
                // Both have progress, pick the latest played
                return (a.userData?.lastPlayedDate ?? .distantPast) > (b.userData?.lastPlayedDate ?? .distantPast)
            } else if aTicks > 0 {
                return true
            } else if bTicks > 0 {
                return false
            } else {
                // Neither has progress, sort by episode number
                return (a.indexNumber ?? 0) < (b.indexNumber ?? 0)
            }
        }
        if let lastWatched = sorted.first(where: { ($0.userData?.playbackPositionTicks ?? 0) > 0 }) {
            // If fully watched, go to next
            if let idx = episodes.firstIndex(where: { $0.id == lastWatched.id }) {
                if let progress = lastWatched.playbackProgress, progress >= 0.95, idx + 1 < episodes.count {
                    return episodes[idx + 1]
                } else {
                    return lastWatched
                }
            }
        }
        // If none watched, return first
        return episodes.first
    }

    var body: some View {
        if let episode = nextEpisode {
            PlayMediaButton(item: episode) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .imageScale(.large)
                    if let season = episode.parentIndexNumber, let ep = episode.indexNumber {
                        Text("S\(season)E\(ep)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let progress = episode.playbackProgress, progress > 0, progress < 1 {
                        Gauge(value: progress) {
                            EmptyView()
                        } currentValueLabel: {
                            EmptyView()
                        } minimumValueLabel: {
                            EmptyView()
                        } maximumValueLabel: {
                            EmptyView()
                        }
                        .gaugeStyle(.accessoryLinearCapacity)
                        .frame(width: 40)
                    }
                    if let remaining = episode.timeRemainingString {
                        Text(remaining)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonBorderShape(.capsule)
            .controlSize(.extraLarge)
            .buttonStyle(.glass)
        }
    }
}
