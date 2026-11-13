//
//  SeerSeasonsView.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI
import JellyfinAPI

struct SeerSeasonsView: View {
    @Bindable var vm: SeerDetailViewModel

    var body: some View {
        SectionContainer(isVisible: !vm.seasons.isEmpty) {
            HorizontalShelf(spacing: episodeSpacing) {
                ForEach(vm.episodes) { episode in
                    SeasonEpisodeCard(item: episode, isPlayable: false)
                        .id(episode.id)
                }
            }
        } header: {
            seasonPicker
            #if os(tvOS)
                .padding(.bottom, 10)
            #endif
        }
        .environment(\.isInSeasonView, true)
        .task(id: vm.selectedSeason) {
            await vm.loadEpisodes()
        }
    }

    private var seasonPicker: some View {
        HStack(spacing: 12) {
            Picker("Season", selection: $vm.selectedSeason) {
                ForEach(vm.seasons) { season in
                    Text(season.displayName).tag(season as SeerSeasonSummary?)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .menuStyle(.button)
            .buttonStyle(.glass)
            .foregroundStyle(.primary)

            if let season = vm.selectedSeason, let status = vm.seasonStatus(for: season) {
                SeerMediaStatusBadge(status: status)
            }
        }
        .scenePadding(.horizontal)
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
