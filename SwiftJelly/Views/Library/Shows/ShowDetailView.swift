import SwiftUI
import JellyfinAPI

struct ShowDetailView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let id: String
    
    @State private var show: BaseItemDto?
    @State private var seasons: [BaseItemDto] = []
    @State private var selectedSeason: BaseItemDto?
    @State private var episodes: [BaseItemDto] = []
    @State private var isLoading = false
    @State private var episodeScrollPosition = ScrollPosition(idType: String.self)
    @State private var refreshTrigger = UUID()
    
    var body: some View {
        ScrollView {
            if let show {
                VStack(alignment: .leading, spacing: 14) {
                    Group {
                        if horizontalSizeClass == .compact {
                            PortraitImageView(item: show)
                        } else {
                            LandscapeImageView(item: show)
                                .frame(maxHeight: 500)
                        }
                    }
                    .backgroundExtensionEffect()
                    .overlay(alignment: .bottomLeading) {
                        ShowPlayButton(show: show, seasons: seasons)
                            .animation(.default, value: show)
                            .environment(\.refresh, fullRefresh)
                            .id("show-play-\(refreshTrigger)") // Force recreation when refresh trigger changes
                            .padding(16)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        if let overview = show.overview {
                            Text(overview)
                                .foregroundStyle(.secondary)
                        }
                    
                        if !seasons.isEmpty {
                            Picker("Season", selection: $selectedSeason) {
                                ForEach(seasons) { season in
                                    Text(season.name ?? "Season").tag(season as BaseItemDto?)
                                }
                            }
                            .labelsHidden()
                            #if os(macOS)
                            .pickerStyle(.segmented)
                            #else
                            .pickerStyle(.menu)
                            .menuStyle(.button)
                            .buttonStyle(.glass)
                            #endif
                        }
                    }
                    .scenePadding(.horizontal)

                    if !episodes.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(episodes) { episode in
                                    PlayableCard(item: episode, showNavigation: false)
                                        .id(episode.id)
                                        .environment(\.refresh, fullRefresh)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                            .scrollTargetLayout()
                        }
                        .scrollPosition($episodeScrollPosition)
                    }
                    
                    if let people = show.people {
                        PeopleScrollView(people: people)
                            .contentMargins(.horizontal, 10)
                    }
                }
                .scenePadding(.bottom)
                
            }
        }
        .overlay {
            if isLoading {
                UniversalProgressView()
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationTitle(show?.name ?? "Show")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await fullRefresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            if show == nil {
                await fetchShow()
            }
        }
        .refreshable {
            await fetchShow()
        }
        .refreshable {
            await fullRefresh()
        }
        .task(id: selectedSeason) {
            await loadEpisodes(for: selectedSeason)
        }
        .task(id: episodes) {
            scrollToLatestEpisode()
        }
    }
    
    private func fullRefresh() async {
        refreshTrigger = UUID()
        
        await fetchShow()
    }
    
    private func fetchShow() async {
        isLoading = true
        defer { isLoading = false }
        do {
            show = try await JFAPI.loadItem(by: id)
            await loadSeasons()
        } catch {
            show = nil
            seasons = []
            episodes = []
        }
    }
    
    private func loadSeasons() async {
        guard let show else { seasons = []; return }
        isLoading = true
        defer { isLoading = false }
        do {
            let loadedSeasons = try await JFAPI.loadSeasons(for: show)
            self.seasons = loadedSeasons.sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }
            
            // Find the latest season to continue watching
            let latestSeason = findLatestSeasonToContinue()
            self.selectedSeason = latestSeason ?? self.seasons.first
            
            if let selected = self.selectedSeason {
                await loadEpisodes(for: selected)
            }
        } catch {
            self.seasons = []
        }
    }
    
    private func findLatestSeasonToContinue() -> BaseItemDto? {
        let sortedSeasons = seasons.sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }
        
        // Find the latest season with any watched content
        var latestWatchedSeason: BaseItemDto?
        
        for season in sortedSeasons.reversed() {
            // Check if season has any watched episodes or in-progress episodes
            if (season.userData?.playCount ?? 0) > 0 || 
               (season.userData?.playbackPositionTicks ?? 0) > 0 ||
               season.userData?.isPlayed == true {
                latestWatchedSeason = season
                break
            }
        }
        
        // If we found a watched season, check if it's fully completed
        if let watchedSeason = latestWatchedSeason {
            // If the season is fully watched, try to find the next season
            if watchedSeason.userData?.isPlayed == true {
                if let currentIndex = sortedSeasons.firstIndex(where: { $0.id == watchedSeason.id }),
                   currentIndex + 1 < sortedSeasons.count {
                    return sortedSeasons[currentIndex + 1]
                }
            }
            return watchedSeason
        }
        
        // If no watched content found, return first season
        return sortedSeasons.first
    }
    
    private func loadEpisodes(for season: BaseItemDto?) async {
        guard let show, let season else { episodes = []; return }
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
