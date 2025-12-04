import SwiftUI
import JellyfinAPI

struct ShowSeasonsView: View {
    @Bindable var vm: ShowDetailViewModel
    @State private var episodeScrollPosition = ScrollPosition(idType: String.self)
    
    #if os(tvOS)
    private let episodeSpacing: CGFloat = 32
    #else
    private let episodeSpacing: CGFloat = 15
    #endif
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !vm.seasons.isEmpty {
                Picker("Season", selection: $vm.selectedSeason) {
                    ForEach(vm.seasons) { season in
                        Text(season.name ?? "Season").tag(season as BaseItemDto?)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                .labelsHidden()
                .pickerStyle(.menu)
                .menuStyle(.button)
                .buttonStyle(.glass)
#if os(tvOS)
                .frame(maxWidth: .infinity, alignment: .leading)
                .focusSection()
#endif
            }
            
            if !vm.episodes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: episodeSpacing) {
                        ListStartItemSpacer()

                        ForEach(vm.episodes) { episode in
                            PlayableCard(item: episode, showRealname: true, showDescription: true)
                                .id(episode.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition($episodeScrollPosition)
                #if os(tvOS)
                .scrollClipDisabled()
                .focusSection()
                #endif
            } else {
                ProgressView()
                    .controlSize(.large)
                    .frame(height: 200)
            }
        }
        .task(id: vm.selectedSeason) {
            await vm.updateEpisodesForSelectedSeason()
            scrollToLatestEpisode()
        }
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
        if targetEpisode == nil { targetEpisode = sortedEpisodes.first }
        if let episode = targetEpisode, let episodeId = episode.id {
            withAnimation { episodeScrollPosition.scrollTo(id: episodeId, anchor: .leading) }
        }
    }
}
