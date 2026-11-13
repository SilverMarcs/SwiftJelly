//
//  EpisodeAirDateOverlay.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI
import JellyfinAPI

struct EpisodeAirDateOverlay: View {
    @Environment(\.isInSeasonView) private var isInSeasonView

    let item: BaseItemDto
    var showEpisodeInformation: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.caption2)

            if let premiereDate = item.premiereDate {
                Text(premiereDate, format: .dateTime.day().month().year())
                    .font(.caption2)
            } else {
                Text("--")
                    .font(.caption2)
            }

            Spacer()

            if showEpisodeInformation, let episodeText = isInSeasonView ? item.episodeOnlyString : item.seasonEpisodeString {
                Text(episodeText)
                    .font(.caption2)
            }
        }
        .foregroundStyle(.white)
    }
}
