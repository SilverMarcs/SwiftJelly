import SwiftUI
import JellyfinAPI

struct ShowPlayButton: View {
    let show: BaseItemDto
    let seasons: [BaseItemDto]
    
    @State private var nextEpisode: BaseItemDto? = nil
    @State private var isLoading = true
    
    var body: some View {
        HStack {
            if isLoading {
                // Loading placeholder while fetching
                loadingButton
            } else if let nextEpisode {
                // Real playback UI when we have an episode
                PlayMediaButton(item: nextEpisode) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        
                        if let season = nextEpisode.parentIndexNumber,
                           let ep = nextEpisode.indexNumber {
                            Text("S\(season)E\(ep)")
                                .font(.caption)
                        }
                        
                        if let progress = nextEpisode.playbackProgress,
                           progress > 0, progress < 0.95 {
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
                        
                        if let remaining = nextEpisode.timeRemainingString {
                            Text(remaining)
                                .font(.caption)
                        }
                    }
                }
                .tint(Color(.accent).secondary)
                .buttonBorderShape(.capsule)
                .controlSize(.extraLarge)
                .buttonStyle(.glassProminent)
                // Consider re-enabling with a flag after first load to avoid initial flicker:
                // .animation(.default, value: nextEpisode)
                
            } else {
                // Requested change: when there is "no episode", show the same loading UI
                loadingButton
            }
            MarkPlayedButton(item: nextEpisode ?? BaseItemDto())
            FavoriteButton(item: nextEpisode ?? BaseItemDto())
        }
        // Trigger load when seasons identity changes
        .task(id: seasons.map { $0.id ?? "" }.joined(separator: "|")) {
            await refreshNextEpisode()
        }
    }
    
    // MARK: - Subviews
    
    private var loadingButton: some View {
        Button(action: {}) {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.mini)
                Text("Loading…")
                    .font(.caption)
            }

        }
        .tint(Color(.accent).secondary)
        .buttonBorderShape(.capsule)
        .controlSize(.extraLarge)
        .buttonStyle(.glassProminent)
    }
}

// MARK: - Loading / Selection

private extension ShowPlayButton {
    func refreshNextEpisode() async {
        await MainActor.run {
            isLoading = true
            nextEpisode = nil
        }
        
        let episode = await loadNextEpisode(for: show, seasons: seasons)
        
        await MainActor.run {
            nextEpisode = episode
            isLoading = false
        }
    }
    
    func loadNextEpisode(for show: BaseItemDto, seasons: [BaseItemDto]) async -> BaseItemDto? {
        guard !seasons.isEmpty else { return nil }
        
        let sortedSeasons = seasons.sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }
        
        // Try per season in order
        for season in sortedSeasons {
            do {
                let episodes = try await JFAPI.loadEpisodes(for: show, season: season)
                let sortedEpisodes = episodes.sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }
                
                // Prefer in-progress but not finished
                if let inProgress = sortedEpisodes.first(where: { ep in
                    let hasProgress = (ep.userData?.playbackPositionTicks ?? 0) > 0
                    let isFullyWatched = ep.userData?.isPlayed == true || (ep.playbackProgress ?? 0) >= 0.95
                    return hasProgress && !isFullyWatched
                }) {
                    return inProgress
                }
                
                // First fully-unwatched
                if let firstUnwatched = sortedEpisodes.first(where: { ep in
                    let isWatched = ep.userData?.isPlayed == true || (ep.playbackProgress ?? 0) >= 0.95
                    return !isWatched
                }) {
                    return firstUnwatched
                }
                
                // else: this season finished, continue
            } catch {
                // Failed to load this season; try next
                continue
            }
        }
        
        // All watched: choose last episode of last season
        if let lastSeason = sortedSeasons.last {
            do {
                let episodes = try await JFAPI.loadEpisodes(for: show, season: lastSeason)
                if let last = episodes.sorted(by: { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }).last {
                    return last
                }
            } catch {
                // If this also fails, return nil
            }
        }
        
        return nil
    }
}
