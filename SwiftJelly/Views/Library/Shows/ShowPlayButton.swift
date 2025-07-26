import SwiftUI
import JellyfinAPI

struct ShowPlayButton: View {
    let show: BaseItemDto
    let episodes: [BaseItemDto]

    private var nextEpisode: BaseItemDto? {
        // Sort episodes by episode number for proper order
        let sortedEpisodes = episodes.sorted { (a, b) in
            (a.indexNumber ?? 0) < (b.indexNumber ?? 0)
        }
        
        // Find episode with in-progress playback (not fully watched)
        if let inProgressEpisode = sortedEpisodes.first(where: { episode in
            let hasProgress = (episode.userData?.playbackPositionTicks ?? 0) > 0
            let isFullyWatched = episode.userData?.isPlayed == true || 
                               (episode.playbackProgress ?? 0) >= 0.95
            return hasProgress && !isFullyWatched
        }) {
            return inProgressEpisode
        }
        
        // Find first unwatched episode
        if let firstUnwatched = sortedEpisodes.first(where: { episode in
            let isWatched = episode.userData?.isPlayed == true || 
                           (episode.playbackProgress ?? 0) >= 0.95
            return !isWatched
        }) {
            return firstUnwatched
        }
        
        // If all episodes are watched, return the last episode
        return sortedEpisodes.last
    }

    var body: some View {
        if let episode = nextEpisode {
            HStack {
                PlayMediaButton(item: episode) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        
                        if let season = episode.parentIndexNumber, let ep = episode.indexNumber {
                            Text("S\(season)E\(ep)")
                                .font(.caption)
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
                            .tint(.white)
                            .gaugeStyle(.accessoryLinearCapacity)
                            .controlSize(.mini)
                            .frame(width: 40)
                        }
                        
                        if let remaining = episode.timeRemainingString {
                            Text(remaining)
                                .font(.caption)
                        }
                    }
                }
                .tint(Color(.accent).secondary)
                .buttonBorderShape(.capsule)
                .controlSize(.extraLarge)
                .buttonStyle(.glassProminent)
                
                MarkPlayedButton(item: episode)
            }
        }
    }
}
