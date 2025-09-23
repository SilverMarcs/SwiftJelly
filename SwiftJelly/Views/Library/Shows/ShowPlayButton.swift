import SwiftUI
import JellyfinAPI

struct ShowPlayButton: View {
    let show: BaseItemDto
    let seasons: [BaseItemDto]
    
    @State private var nextEpisode: BaseItemDto? = nil
    @State private var isLoading = true
    
    var body: some View {
        HStack {
            animatedButton
            MarkPlayedButton(item: nextEpisode ?? BaseItemDto())
            FavoriteButton(item: nextEpisode ?? BaseItemDto())
        }
        // Trigger load when seasons identity changes
        .task(id: seasons.map { $0.id ?? "" }.joined(separator: "|")) {
            await refreshNextEpisode()
        }
    }
    
    private var animatedButton: some View {
        Button(action: {}) {
            ZStack {
                // Loading content
                HStack(spacing: 8) {
                    ProgressView().controlSize(.mini)
                    Text("Loading…").font(.caption)
                }
                .opacity(isLoading || nextEpisode == nil ? 1 : 0)

                // Play content
                Group {
                    if let nextEpisode {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            if let s = nextEpisode.parentIndexNumber, let e = nextEpisode.indexNumber {
                                Text("S\(s)E\(e)").font(.caption)
                            }
                            if let progress = nextEpisode.playbackProgress, progress > 0, progress < 0.95 {
                                Gauge(value: progress) { EmptyView() } currentValueLabel: { EmptyView() } minimumValueLabel: { EmptyView() } maximumValueLabel: { EmptyView() }
                                    .tint(.white)
                                    .gaugeStyle(.accessoryLinearCapacity)
                                    .controlSize(.mini)
                                    .frame(width: 40)
                            }
                            if let remaining = nextEpisode.timeRemainingString {
                                Text(remaining).font(.caption)
                            }
                        }
                    }
                }
                .opacity(isLoading || nextEpisode == nil ? 0 : 1)
            }
            .animation(.easeInOut(duration: 0.2), value: isLoading)
            .animation(.easeInOut(duration: 0.2), value: nextEpisode?.id)
        }
        .tint(Color(.accent).secondary)
        .buttonBorderShape(.capsule)
        .controlSize(.extraLarge)
        .buttonStyle(.glassProminent)
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
