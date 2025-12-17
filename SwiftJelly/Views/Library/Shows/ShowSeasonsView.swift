import SwiftUI
import JellyfinAPI

struct ShowSeasonsView: View {
    @Bindable var vm: ShowDetailViewModel
    @State private var episodeScrollPosition = ScrollPosition(idType: String.self)
    
    var body: some View {
        // TODO: use section in tvos to put teh season picker
        VStack(alignment: .leading, spacing: 16) {
            if vm.isLoadingEpisodes && vm.seasons.isEmpty {
                ProgressView()
                    .controlSize(.extraLarge)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            }
            
            seasonPicker
            
            scroller
        }
        .task(id: vm.selectedSeason) {
            await vm.updateEpisodesForSelectedSeason()
            scrollToLatestEpisode()
        }
    }
    
    @ViewBuilder
    private var seasonPicker: some View {
        if !vm.seasons.isEmpty {
            Picker("Season", selection: $vm.selectedSeason) {
                ForEach(vm.seasons) { season in
                    Text(season.name ?? "Season").tag(season as BaseItemDto?)
                }
            }
            .scenePadding(.horizontal)
            .padding(.top)
            .labelsHidden()
            .pickerStyle(.menu)
            .menuStyle(.button)
            .buttonStyle(.glass)
            .foregroundStyle(.primary)
            #if os(tvOS)
            .focusSection()
            #endif
        }
    }

    private var scroller: some View {
        SectionContainer("Seasons", showHeader: false) {
            HorizontalShelf(spacing: episodeSpacing) {
                ForEach(vm.episodes) { episode in
                    PlayableCard(item: episode, showRealname: true, showDescription: true)
                        .id(episode.id)
                }
            }
            .scrollPosition($episodeScrollPosition)
        }
        .environment(\.isInSeasonView, true)
        #if os(tvOS)
        .focusSection()
        #endif
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
        if targetEpisode == nil { targetEpisode = sortedEpisodes.first } // why .last vs .first?
        if let episode = targetEpisode, let episodeId = episode.id {
            withAnimation { episodeScrollPosition.scrollTo(id: episodeId, anchor: .trailing) } // trailing so it doesnt getcut off for smaller window sizes
        }
    }

    private var episodeSpacing: CGFloat {
        #if os(tvOS)
        32
        #else
        8
        #endif
    }
}
