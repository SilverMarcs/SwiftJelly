import SwiftUI
import JellyfinAPI

struct ShowSeasonsView: View {
    @Bindable var vm: ShowDetailViewModel
    @State private var episodeScrollPosition = ScrollPosition(idType: String.self)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            if vm.isLoadingEpisodes && vm.seasons.isEmpty {
                UniversalProgressView()
            }

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
            .labelsHidden()
            .pickerStyle(.menu)
            .menuStyle(.button)
            .buttonStyle(.glass)
            .foregroundStyle(.primary)
            #if os(tvOS)
            .frame(maxWidth: .infinity, alignment: .leading)
            .focusSection()
            #endif
        }
    }

    private var scroller: some View {
        SectionContainer {
            HorizontalShelf(spacing: episodeSpacing) {
                ForEach(vm.episodes) { episode in
                    PlayableCard(item: episode, showRealname: true, showDescription: true)
                        .frame(width: cardWidth)
                        .id(episode.id)
                }
            }
            .scrollPosition($episodeScrollPosition)
        } header: {
            seasonPicker
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

    private var cardWidth: CGFloat {
        #if os(tvOS)
        480
        #elseif os(macOS)
        300
        #else
        280
        #endif
    }
}
