import SwiftUI
import JellyfinAPI

struct ShowSeasonsView: View {
    @Bindable var vm: ShowDetailViewModel
    @State private var episodeScrollPosition = ScrollPosition(idType: String.self)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !vm.seasons.isEmpty {
                Picker("Season", selection: $vm.selectedSeason) {
                    ForEach(vm.seasons) { season in
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
                .task(id: vm.selectedSeason) { 
                    await vm.updateEpisodesForSelectedSeason() 
                }
            }
            
            if !vm.episodes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(vm.episodes) { episode in
                            PlayableCard(item: episode, showNavigation: false)
                                .id(episode.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition($episodeScrollPosition)
                .onChange(of: vm.episodes) { _, _ in scrollToLatestEpisode() }
            }
        }
//        .overlay { if vm.isLoadingEpisodes { UniversalProgressView() } }
    }
    
    private func scrollToLatestEpisode() {
        let episodes = vm.episodes
        guard !episodes.isEmpty else { return }
        let sortedEpisodes = episodes.sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }
        var targetEpisode: BaseItemDto? = sortedEpisodes.first { ep in
            let hasProgress = (ep.userData?.playbackPositionTicks ?? 0) > 0
            let isFullyWatched = ep.userData?.isPlayed == true || (ep.playbackProgress ?? 0) >= 0.95
            return hasProgress && !isFullyWatched
        }
        if targetEpisode == nil {
            targetEpisode = sortedEpisodes.first { ep in
                let isWatched = ep.userData?.isPlayed == true || (ep.playbackProgress ?? 0) >= 0.95
                return !isWatched
            }
        }
        if targetEpisode == nil { targetEpisode = sortedEpisodes.last }
        if let episode = targetEpisode, let episodeId = episode.id {
            withAnimation { episodeScrollPosition.scrollTo(id: episodeId, anchor: .trailing) }
        }
    }
}

