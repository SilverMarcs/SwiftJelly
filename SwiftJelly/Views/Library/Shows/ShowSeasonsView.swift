import SwiftUI
import JellyfinAPI

struct ShowSeasonsView: View {
    @Bindable var vm: ShowDetailViewModel
    @State private var episodeScrollPosition = ScrollPosition(idType: String.self)
    @FocusState private var focusedEpisodeID: String?
    @State private var alreadyAutoSelectedSeason = false
    
    var body: some View {
        SectionContainer {
            HorizontalShelf(spacing: episodeSpacing) {
                ForEach(vm.episodes) { episode in
                    SeasonEpisodeCard(item: episode)
                        .id(episode.id)
                }
            }
            .scrollPosition($episodeScrollPosition)
        } header: {
            seasonPicker
            #if os(tvOS)
                .padding(.bottom, 10) // To prevent the season picker to collide with the episode card, when the description is focused
            #endif
        }
        .environment(\.isInSeasonView, true)
        .task(id: vm.selectedSeason) {
            await vm.updateEpisodesForSelectedSeason()
            if !alreadyAutoSelectedSeason {
                alreadyAutoSelectedSeason = true
                scrollToLatestEpisode()
            }
        }
    }
    
    @ViewBuilder
    private var seasonPicker: some View {
        Picker("Season", selection: $vm.selectedSeason) {
            if vm.selectedSeason == nil {
                Text("Seasons").tag(nil as BaseItemDto?)
            }
            
            if !vm.seasons.isEmpty {
                ForEach(vm.seasons) { season in
                    Text(season.name ?? "Season").tag(season as BaseItemDto)
                }
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
    
    private func scrollToLatestEpisode() {
        let episodes = vm.episodes
        guard !episodes.isEmpty else { return }

        let sortedEpisodes = episodes.sorted { ($0.base?.indexNumber ?? 0) < ($1.base?.indexNumber ?? 0) }
        
        
        var targetEpisode: ViewListItem<BaseItemDto>? = sortedEpisodes.first { ep in
            let hasProgress = (ep.base?.userData?.playbackPositionTicks ?? 0) > 0
            let isFullyWatched = ep.base?.userData?.isPlayed == true || (ep.base?.playbackProgress ?? 0) >= 0.95
            return hasProgress && !isFullyWatched
        }

        if targetEpisode == nil {
            targetEpisode = sortedEpisodes.first { ep in
                let isWatched = ep.base?.userData?.isPlayed == true || (ep.base?.playbackProgress ?? 0) >= 0.95
                return !isWatched
            }
        }
        if targetEpisode == nil { targetEpisode = sortedEpisodes.first } // why .last vs .first?
        if let episode = targetEpisode {
            withAnimation {
                episodeScrollPosition.scrollTo(id: episode.id, anchor: .trailing) // trailing so it doesnt getcut off for smaller window sizes
                focusedEpisodeID = episode.id
            }
        }
    }

    private var episodeSpacing: CGFloat {
        #if os(tvOS)
        50
        #else
        8
        #endif
    }

}
