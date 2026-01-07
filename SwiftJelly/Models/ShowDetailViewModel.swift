import Foundation
import JellyfinAPI
import SwiftUI

@Observable
class ShowDetailViewModel {
    // Input
    private(set) var show: BaseItemDto
    
    // Seasons / Episodes
    private(set) var seasons: [BaseItemDto] = []
    var selectedSeason: BaseItemDto? = nil
    private(set) var episodes: [BaseItemDto] = []
    private var allEpisodes: [String: [BaseItemDto]] = [:]
     
    // Next Episode / play button
    private(set) var nextEpisode: BaseItemDto? = nil
    
    // Loading states
    var isLoading: Bool = false
    var isLoadingEpisodes: Bool = false
    
    var playButtonDisabled: Bool { nextEpisode == nil || isLoading }
    
    init(item: BaseItemDto) {
        self.show = item
    }
    
    // refreshes everything: show metadata, seasons, episodes, next episode
    func refreshAll() async {
        isLoading = true
        defer { isLoading = false }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadShowDetail() }
            group.addTask { await self.loadSeasonsAndEpisodes() }
        }
    }
    
    // Quick load just the next episode for hero/play button (no seasons/episodes)
    func loadQuickNextEpisode() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let seriesID = show.type == .episode ? (show.seriesID ?? show.id ?? "") : (show.id ?? "")
            guard !seriesID.isEmpty else { return }
            
            // Try NextUp API first (fast)
            if let nextUp = try await JFAPI.loadNextUpItems(limit: 1, seriesID: seriesID).first {
                withAnimation { nextEpisode = nextUp }
                return
            }
            
            // Fallback: try resume items
            if let resumed = try await JFAPI.loadResumeItems(limit: 10, parentID: seriesID)
                .sorted(by: { activityDate(for: $0) > activityDate(for: $1) })
                .first(where: { $0.type == .episode }) {
                withAnimation { nextEpisode = resumed }
            }
        } catch {
            print("Quick next episode load failed: \(error)")
        }
    }
    
    func updateEpisodesForSelectedSeason() async {
        guard let selectedSeason else { episodes = []; return }
        let sid = selectedSeason.id ?? ""
        episodes = allEpisodes[sid] ?? []
    }
    
    func markEpisodePlayed(_ episode: BaseItemDto) async {
        do {
            try await JFAPI.toggleItemPlayedStatus(item: episode)
            await loadSeasonsAndEpisodes()
        } catch { 
            print("Toggle played failed: \(error)") 
        }
    }
    
    // loads show metadata like genre studios etc
    func loadShowDetail() async {
        do {
            let itemId = show.type == .episode ? (show.seriesID ?? show.id ?? "") : (show.id ?? "")
            guard !itemId.isEmpty else { return }
            show = try await JFAPI.loadItem(by: itemId)
        } catch { 
            print("Reload show failed: \(error)") 
        }
    }
    
    // loads all seasons and episodes, inferring seasons if needed
    func loadSeasonsAndEpisodes() async {
        isLoadingEpisodes = true
        defer { isLoadingEpisodes = false }
        do {
            let allEps = try await JFAPI.loadAllEpisodes(for: show)
            
            // Group episodes by seasonID
            let grouped = Dictionary(grouping: allEps) { $0.seasonID ?? "" }
            
            var inferredSeasons: [BaseItemDto] = []
            allEpisodes = [:]
            
            for (seasonID, eps) in grouped where !seasonID.isEmpty {
                if let firstEp = eps.first {
                    // Create season from episode data
                    var season = BaseItemDto()
                    season.id = seasonID
                    season.name = firstEp.seasonName
                    season.indexNumber = firstEp.parentIndexNumber
                    season.type = .season
                    season.seriesID = show.id
                    season.seriesName = show.name
                    // Add other fields if needed, but for now, id, name, indexNumber suffice
                    
                    inferredSeasons.append(season)
                    
                    // Sort and store episodes
                    allEpisodes[seasonID] = eps.sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }
                }
            }
            
            seasons = inferredSeasons.sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }
        } catch {
            seasons = []
            episodes = []
            allEpisodes = [:]
        }
        
        await computeNextEpisode()
        await updateEpisodesForSelectedSeason()
    }
    
    private func computeNextEpisode() async {
        var computed: BaseItemDto? = nil
        
        let sortedSeasons = seasons
        for season in sortedSeasons {
            let sid = season.id ?? ""
            let sortedEpisodes = allEpisodes[sid] ?? []
            
            // Prefer in-progress but not finished
            if let inProgress = sortedEpisodes.first(where: { ep in
                let hasProgress = (ep.userData?.playbackPositionTicks ?? 0) > 0
                let isFullyWatched = ep.userData?.isPlayed == true || (ep.playbackProgress ?? 0) >= 0.95
                return hasProgress && !isFullyWatched
            }) {
                computed = inProgress
                break
            }
            
            // First fully-unwatched
            if let firstUnwatched = sortedEpisodes.first(where: { ep in
                let isWatched = ep.userData?.isPlayed == true || (ep.playbackProgress ?? 0) >= 0.95
                return !isWatched
            }) {
                computed = firstUnwatched
                break
            }
        }
        
        // All watched: choose last episode of last season
        if computed == nil, let lastSeason = sortedSeasons.last {
            let sid = lastSeason.id ?? ""
            computed = allEpisodes[sid]?.last
        }
        
        // Single animated assignment
        withAnimation {
            nextEpisode = computed
            isLoading = false
        }
        
        // Auto-select season if different
        if let ne = computed, let sid = ne.seasonID, let targetSeason = seasons.first(where: { $0.id == sid }) {
            if selectedSeason?.id != targetSeason.id {
                withAnimation {
                    selectedSeason = targetSeason
                }
                await updateEpisodesForSelectedSeason()
            }
        }
    }
    
    private func activityDate(for item: BaseItemDto) -> Date {
        if let played = item.userData?.lastPlayedDate {
            return played
        }
        if let ticks = item.userData?.playbackPositionTicks, ticks > 0 {
            return Date()
        }
        return item.premiereDate ?? item.dateCreated ?? .distantPast
    }
}
