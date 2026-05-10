import Foundation
import JellyfinAPI
import SwiftUI

struct EpisodeItem {
    var episodeItem: BaseItemDto?
}

@Observable
class ShowDetailViewModel {
    private static var episodesPlaceholder: [ViewListItem<BaseItemDto>] = withPlaceholderItems(size: 6)
    
    // Input
    private(set) var show: BaseItemDto
    
    // Seasons / Episodes
    private(set) var seasons: [BaseItemDto] = []
    var selectedSeason: BaseItemDto? = nil
    
    private(set) var episodes: [ViewListItem] = episodesPlaceholder
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
            group.addTask { await self.loadQuickNextEpisode() }
            group.addTask { await self.loadSeasonsAndEpisodes() }
        }
    }
    
    // Quick load just the next episode for hero/play button (no seasons/episodes)
    func loadQuickNextEpisode() async {
        isLoading = true
        do {
            let seriesID = show.type == .episode ? (show.seriesID ?? show.id ?? "") : (show.id ?? "")
            guard !seriesID.isEmpty else { return }

            if let resumed = try await JFAPI.loadResumeItems(limit: 10, parentID: seriesID)
                .sorted(by: { activityDate(for: $0) > activityDate(for: $1) })
                .first(where: { $0.type == .episode }) {
                withAnimation {
                    nextEpisode = resumed
                    isLoading = false
                }

                return
            }

            // Try NextUp API as backup
            if let nextUp = try await JFAPI.loadNextUpItems(limit: 1, seriesID: seriesID).first {
                withAnimation {
                    nextEpisode = nextUp
                    isLoading = false
                }
                return
            }

            if allEpisodes.count > 0 {
                await computeNextEpisode()
            }
        } catch {
            print("Quick next episode load failed: \(error)")
        }
    }
    
    func autoSelectSeasonAndEpisode() async {
        if let ne = nextEpisode, let sid = ne.seasonID, let targetSeason = seasons.first(where: { $0.id == sid }) {
            if selectedSeason?.id != targetSeason.id {
                selectedSeason = targetSeason

                await updateEpisodesForSelectedSeason()
            }
        }
    }
    
    func updateEpisodesForSelectedSeason() async {
        guard let selectedSeason else { episodes = ShowDetailViewModel.episodesPlaceholder; return }
        let sid = selectedSeason.id ?? ""

        if let eps = allEpisodes[sid] {
            episodes.update(with: eps)
            isLoadingEpisodes = false
        } else {
            // Episodes for this season haven't loaded yet — keep placeholders.
            episodes = ShowDetailViewModel.episodesPlaceholder
            isLoadingEpisodes = true
        }
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
    
    // Loads seasons first, then fetches episodes for every season in parallel.
    // Each season's episodes populate as soon as they arrive; the selected
    // season's episode list updates live.
    func loadSeasonsAndEpisodes() async {
        isLoadingEpisodes = true
        let seriesID = show.type == .episode ? (show.seriesID ?? show.id ?? "") : (show.id ?? "")
        guard !seriesID.isEmpty else { isLoadingEpisodes = false; return }
        var seriesShow = show
        if show.type == .episode { seriesShow = BaseItemDto(); seriesShow.id = seriesID }

        let loadedSeasons: [BaseItemDto]
        do {
            loadedSeasons = try await JFAPI.loadSeasons(for: seriesShow)
                .sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }
        } catch {
            seasons = []
            episodes.update(with: (0..<10).map { _ in BaseItemDto() })
            allEpisodes = [:]
            isLoadingEpisodes = false
            return
        }

        seasons = loadedSeasons
        allEpisodes = [:]
        await autoSelectSeasonAndEpisode()
        if selectedSeason == nil, let first = loadedSeasons.first {
            selectedSeason = first
            await updateEpisodesForSelectedSeason()
        }

        await withTaskGroup(of: (String, [BaseItemDto]).self) { group in
            for season in loadedSeasons {
                guard let sid = season.id, !sid.isEmpty else { continue }
                group.addTask {
                    let eps = (try? await JFAPI.loadEpisodes(for: seriesShow, seasonID: sid)) ?? []
                    return (sid, eps.sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) })
                }
            }
            for await (sid, eps) in group {
                allEpisodes[sid] = eps
                if selectedSeason?.id == sid {
                    episodes.update(with: eps)
                    isLoadingEpisodes = false
                }
            }
        }

        isLoadingEpisodes = false

        if nextEpisode == nil {
            await computeNextEpisode()
        }
        await autoSelectSeasonAndEpisode()
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

        await autoSelectSeasonAndEpisode()
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
