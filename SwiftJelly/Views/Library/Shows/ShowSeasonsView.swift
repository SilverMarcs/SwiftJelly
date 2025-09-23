import SwiftUI
import JellyfinAPI

struct ShowSeasonsView: View {
    @Environment(\.refresh) var refresh
    
    let show: BaseItemDto
    
    @State private var seasons: [BaseItemDto] = []
    @State private var selectedSeason: BaseItemDto?
    @State private var episodes: [BaseItemDto] = []
    @State private var episodeScrollPosition = ScrollPosition(idType: String.self)
    
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !seasons.isEmpty {
                Picker("Season", selection: $selectedSeason) {
                    ForEach(seasons) { season in
                        Text(season.name ?? "Season").tag(season as BaseItemDto?)
                    }
                }
                .scenePadding(.horizontal)
                .labelsHidden()
                #if os(macOS)
                .pickerStyle(.segmented)
                #else
                .pickerStyle(.menu)
                .menuStyle(.button)
                .buttonStyle(.glass)
                #endif
            }

            if !episodes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(episodes) { episode in
                            PlayableCard(item: episode, showNavigation: false)
                                .id(episode.id)
                                .environment(\.refresh, refreshEpisodes)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition($episodeScrollPosition)
            }
        }
        .overlay {
            if isLoading {
                UniversalProgressView()
            }
        }
                .task {
            await loadSeasons()
        }
        .task(id: selectedSeason) {
            await loadEpisodes(for: selectedSeason)
        }
        .task(id: episodes) {
            scrollToLatestEpisode()
        }
    }
    
    private func refreshEpisodes() async {
        async let a: Void = refresh()
        async let b: Void = loadEpisodes(for: selectedSeason)
        _ = await (a, b) // wait for both to finish
    }
    
    private func loadSeasons() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loadedSeasons = try await JFAPI.loadSeasons(for: show)
            self.seasons = loadedSeasons.sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }
            
            // Find the season of the next episode
            let nextEpisode = await JFAPI.loadNextEpisode(for: show)
            self.selectedSeason = seasons.first { $0.id == nextEpisode?.seasonID } ?? self.seasons.first
            
            if let selected = self.selectedSeason {
                await loadEpisodes(for: selected)
            }
        } catch {
            self.seasons = []
        }
    }
    
    private func loadEpisodes(for season: BaseItemDto?) async {
        isLoading = true
        defer { isLoading = false }
        
        guard let season else { episodes = []; return }
        do {
            let loadedEpisodes = try await JFAPI.loadEpisodes(for: show, season: season)
            self.episodes = loadedEpisodes.sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }
        } catch {
            self.episodes = []
        }
    }
    
    private func scrollToLatestEpisode() {
        guard !episodes.isEmpty else { return }
        
        let sortedEpisodes = episodes.sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }
        
        // Find episode to scroll to (in-progress or next unwatched)
        var targetEpisode: BaseItemDto?
        
        // First, look for in-progress episode
        targetEpisode = sortedEpisodes.first { episode in
            let hasProgress = (episode.userData?.playbackPositionTicks ?? 0) > 0
            let isFullyWatched = episode.userData?.isPlayed == true || 
                               (episode.playbackProgress ?? 0) >= 0.95
            return hasProgress && !isFullyWatched
        }
        
        // If no in-progress episode, find first unwatched
        if targetEpisode == nil {
            targetEpisode = sortedEpisodes.first { episode in
                let isWatched = episode.userData?.isPlayed == true || 
                               (episode.playbackProgress ?? 0) >= 0.95
                return !isWatched
            }
        }
        
        // If all episodes are watched, scroll to last episode
        if targetEpisode == nil {
            targetEpisode = sortedEpisodes.last
        }
        
        if let episode = targetEpisode, let episodeId = episode.id {
            withAnimation {
                episodeScrollPosition.scrollTo(id: episodeId, anchor: .trailing)
            }
        }
    }
}
