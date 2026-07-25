import SwiftUI
import JellyfinAPI

struct ShowSeasonsView: View {
    @Bindable var vm: ShowDetailViewModel
    @State private var episodeScrollPosition = ScrollPosition(idType: String.self)
    // Once the user picks a season themselves, stop auto-scrolling so the
    // selection isn't yanked back to the latest episode of another season.
    @State private var hasUserInteracted = false
    
    var body: some View {
        SectionContainer {
            HorizontalShelf(spacing: episodeSpacing) {
                ForEach(vm.episodes) { episode in
                    SeasonEpisodeCard(item: episode)
                        .id(episode.id)                }
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
        }
        .onChange(of: vm.episodes.first?.base?.id, initial: true) {
            // Only scroll to the latest episode on first presentation. As soon
            // as the user has picked a season, leave their selection alone.
            guard !hasUserInteracted else { return }
            guard vm.episodes.contains(where: { $0.base != nil }) else { return }
            scrollToLatestEpisode()
        }
    }
    
    @ViewBuilder
    private var seasonPicker: some View {
        Picker("Season", selection: seasonSelection) {
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

    // Wraps the season selection so that a user-driven change (the only path
    // that calls this setter) marks the view as interacted. Programmatic
    // updates to `vm.selectedSeason` bypass this and keep auto-scroll enabled.
    private var seasonSelection: Binding<BaseItemDto?> {
        Binding(
            get: { vm.selectedSeason },
            set: { newValue in
                hasUserInteracted = true
                vm.selectedSeason = newValue
            }
        )
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
