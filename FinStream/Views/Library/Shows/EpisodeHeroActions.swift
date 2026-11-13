//
//  EpisodeHeroActions.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI
import JellyfinAPI

struct EpisodeHeroActions: View {
    @Binding var episode: BaseItemDto
    var externalFocusNamespace: Namespace.ID? = nil
    var playFocus: FocusState<Bool>.Binding? = nil

    var body: some View {
        HeroActionButtons(
            context: .carousel,
            usesGlassContainer: true,
            infoItem: episode,
            markPlayedItem: episode,
            favoriteItem: nil,
            redactWhenEmpty: episode,
            externalFocusNamespace: externalFocusNamespace,
            playFocus: playFocus
        ) {
            EpisodePlayButton(item: episode)
        }
        .environment(\.refresh, refresh)
    }

    private func refresh() async {
        guard let id = episode.id, !id.isEmpty else { return }
        do {
            episode = try await JFAPI.loadItem(by: id)
        } catch {
            print("Error refreshing episode: \(error)")
        }
    }
}
