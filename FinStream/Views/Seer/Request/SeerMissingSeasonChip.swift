//
//  SeerMissingSeasonChip.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 13.11.26.
//

import SwiftUI

struct SeerMissingSeasonChip: View {
    let season: SeerSeasonSummary

    var body: some View {
        HStack(spacing: 6) {
            Text(season.displayName)
                .bold()

            if let episodeCount = season.episodeCount {
                Text("\(episodeCount) Ep.")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
        .lineLimit(1)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.fill.tertiary, in: .capsule)
    }
}
