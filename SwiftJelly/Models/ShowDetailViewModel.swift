import Foundation
import JellyfinAPI
import SwiftUI
import Combine

@Observable class ShowDetailViewModel {
    // Input
    private(set) var show: BaseItemDto
    
    // Seasons / Episodes
     private(set) var seasons: [BaseItemDto] = []
     var selectedSeason: BaseItemDto? = nil
     private(set) var episodes: [BaseItemDto] = []
     private var allEpisodes: [String: [BaseItemDto]] = [:]
     
    // Next Episode / play button
     private(set) var nextEpisode: BaseItemDto? = nil
    
     // Loadimg states
     var isLoading: Bool = false
     var isLoadingEpisodes: Bool = false
    
    init(show: BaseItemDto) {
        self.show = show
    }
    
    // MARK: - Public API
    func loadInitial() async {
        await self.reloadSeasonsAndEpisodes()
        await computeNextEpisode()
    }
    
    func refreshAll() async {
        isLoading = true
        defer { isLoading = false }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.reloadShow() }
            group.addTask { await self.reloadSeasonsAndEpisodes() }
        }
        await computeNextEpisode()
    }
    
    func refreshEpisodesOnly() async {
        guard let selectedSeason else { return }
        isLoadingEpisodes = true
        defer { isLoadingEpisodes = false }
        do {
            let eps = try await JFAPI.loadEpisodes(for: show, season: selectedSeason)
            let sortedEps = eps.sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }
            allEpisodes[selectedSeason.id ?? ""] = sortedEps
            episodes = sortedEps
        } catch { 
            episodes = []
            allEpisodes[selectedSeason.id ?? ""] = []
        }
        await computeNextEpisode()
    }
    
    func selectSeason(_ season: BaseItemDto) async {
        guard selectedSeason?.id != season.id else { return }
        selectedSeason = season
        await updateEpisodesForSelectedSeason()
    }
    
    func updateEpisodesForSelectedSeason() async {
        guard let selectedSeason else { episodes = []; return }
        let sid = selectedSeason.id ?? ""
        if allEpisodes[sid] == nil {
            isLoadingEpisodes = true
            defer { isLoadingEpisodes = false }
            do {
                let eps = try await JFAPI.loadEpisodes(for: show, season: selectedSeason)
                let sortedEps = eps.sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }
                allEpisodes[sid] = sortedEps
                episodes = sortedEps
            } catch {
                allEpisodes[sid] = []
                episodes = []
            }
        } else {
            episodes = allEpisodes[sid] ?? []
        }
    }
    
    func markEpisodePlayed(_ episode: BaseItemDto) async {
        do {
            try await JFAPI.toggleItemPlayedStatus(item: episode)
            await refreshEpisodesOnly()
        } catch { print("Toggle played failed: \(error)") }
    }
    
    func refreshAfterPlayback() async {
        // After playback finishes we only need fresh userData for episodes + nextEpisode
        await refreshEpisodesOnly()
    }
    
    // MARK: - Internal loading helpers
    private func reloadShow() async {
        do {
            let itemId = show.type == .episode ? (show.seriesID ?? show.id ?? "") : (show.id ?? "")
            guard !itemId.isEmpty else { return }
            show = try await JFAPI.loadItem(by: itemId)
        } catch { print("Reload show failed: \(error)") }
    }
    
    private func reloadSeasonsAndEpisodes() async {
        do {
            let loaded = try await JFAPI.loadSeasons(for: show)
            let sorted = loaded.sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }
            seasons = sorted
            
            // Load episodes only for the first season initially
            allEpisodes = [:]
            if let firstSeason = sorted.first {
                let eps = try? await JFAPI.loadEpisodes(for: show, season: firstSeason)
                let sortedEps = eps?.sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) } ?? []
                allEpisodes[firstSeason.id ?? ""] = sortedEps
            }
            
            if selectedSeason == nil || !sorted.contains(where: { $0.id == selectedSeason?.id }) {
                selectedSeason = sorted.first
            }
            await updateEpisodesForSelectedSeason()
        } catch {
            seasons = []
            episodes = []
            allEpisodes = [:]
        }
    }
    
    private func computeNextEpisode() async {
        let sortedSeasons = seasons // already sorted in reloadSeasonsAndEpisodes
        for season in sortedSeasons {
            let sid = season.id ?? ""
            var sortedEpisodes = allEpisodes[sid]
            if sortedEpisodes == nil {
                let eps = try? await JFAPI.loadEpisodes(for: show, season: season)
                sortedEpisodes = eps?.sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) } ?? []
                allEpisodes[sid] = sortedEpisodes
            }
            
            // Prefer in-progress but not finished
            if let inProgress = sortedEpisodes!.first(where: { ep in
                let hasProgress = (ep.userData?.playbackPositionTicks ?? 0) > 0
                let isFullyWatched = ep.userData?.isPlayed == true || (ep.playbackProgress ?? 0) >= 0.95
                return hasProgress && !isFullyWatched
            }) {
                nextEpisode = inProgress
                break
            }
            
            // First fully-unwatched
            if let firstUnwatched = sortedEpisodes!.first(where: { ep in
                let isWatched = ep.userData?.isPlayed == true || (ep.playbackProgress ?? 0) >= 0.95
                return !isWatched
            }) {
                nextEpisode = firstUnwatched
                break
            }
            
            // else: this season finished, continue
        }
        
        // All watched: choose last episode of last season
        if nextEpisode == nil, let lastSeason = sortedSeasons.last {
            let sid = lastSeason.id ?? ""
            var sortedEpisodes = allEpisodes[sid]
            if sortedEpisodes == nil {
                let eps = try? await JFAPI.loadEpisodes(for: show, season: lastSeason)
                sortedEpisodes = eps?.sorted(by: { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }) ?? []
                allEpisodes[sid] = sortedEpisodes
            }
            nextEpisode = sortedEpisodes!.last
        }
        
        // Try to auto-select the season of next episode if different
        if let ne = nextEpisode, let sid = ne.seasonID, let targetSeason = seasons.first(where: { $0.id == sid }) {
            if selectedSeason?.id != targetSeason.id { 
                selectedSeason = targetSeason
                await updateEpisodesForSelectedSeason()
            }
        }
    }
}
