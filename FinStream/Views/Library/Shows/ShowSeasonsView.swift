import SwiftUI
import JellyfinAPI

struct ShowSeasonsView: View {
    @Bindable var vm: ShowDetailViewModel
    @State private var episodeScrollPosition = ScrollPosition(idType: String.self)
    @FocusState private var focusedEpisodeID: String?
    
    var body: some View {
        SectionContainer {
            HorizontalShelf(spacing: episodeSpacing) {
                ForEach(vm.episodes) { episode in
                    #if os(tvOS)
                    SeasonEpisodeCard(item: episode, focusedEpisodeID: $focusedEpisodeID)
                        .id(episode.id)
                    #else
                    SeasonEpisodeCard(item: episode)
                        .id(episode.id)
                    #endif
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
        }
        .task(id: vm.episodeScrollTargetID) {
            guard let targetID = vm.episodeScrollTargetID else { return }
            episodeScrollPosition.scrollTo(id: targetID, anchor: .center)
            #if os(tvOS)
            // Let the lazy row lay out the requested card before moving focus.
            await Task.yield()
            guard !Task.isCancelled, vm.episodeScrollTargetID == targetID else { return }
            focusedEpisodeID = targetID
            #endif
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
    
    private var episodeSpacing: CGFloat {
        #if os(tvOS)
        50
        #else
        8
        #endif
    }

}
