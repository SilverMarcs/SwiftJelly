import SwiftUI
import JellyfinAPI

struct ShowPlayButton: View {
    let show: BaseItemDto
    let seasons: [BaseItemDto]
    
    @State private var nextEpisode: BaseItemDto?
    @State private var isLoading = false

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
                        
                        if let progress = episode.playbackProgress, progress > 0, progress < 0.95 {
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
                
                if let episode = nextEpisode {
                    MarkPlayedButton(item: episode)
                }
            }
        } else {
            ProgressView()
                .task(id: seasons) {
                    nextEpisode = nil // Reset state
                    await findNextEpisode()
                }
        }
    }
    
    private func findNextEpisode() async {
        guard !seasons.isEmpty else { return }
        
        let sortedSeasons = seasons.sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }
        
        for season in sortedSeasons {
            do {
                let episodes = try await JFAPI.loadEpisodes(for: show, season: season)
                let sortedEpisodes = episodes.sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }
                
                // Look for in-progress episode first
                if let inProgressEpisode = sortedEpisodes.first(where: { episode in
                    let hasProgress = (episode.userData?.playbackPositionTicks ?? 0) > 0
                    let isFullyWatched = episode.userData?.isPlayed == true || 
                                       (episode.playbackProgress ?? 0) >= 0.95
                    return hasProgress && !isFullyWatched
                }) {
                    nextEpisode = inProgressEpisode
                    return
                }
                
                // Look for first unwatched episode
                if let firstUnwatched = sortedEpisodes.first(where: { episode in
                    let isWatched = episode.userData?.isPlayed == true || 
                                   (episode.playbackProgress ?? 0) >= 0.95
                    return !isWatched
                }) {
                    nextEpisode = firstUnwatched
                    return
                }
                
                // If all episodes in this season are watched, continue to next season
            } catch {
                continue
            }
        }
        
        // If we get here, all episodes are watched - set to last episode of last season
        if let lastSeason = sortedSeasons.last {
            do {
                let episodes = try await JFAPI.loadEpisodes(for: show, season: lastSeason)
                nextEpisode = episodes.sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }.last
            } catch {
                nextEpisode = nil
            }
        }
    }
}
