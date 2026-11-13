//
//  SeerSeasonToggleRow.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI

struct SeerSeasonToggleRow: View {
    let season: SeerSeasonSummary
    let status: SeerMediaStatus?
    @Binding var isOn: Bool

    private var state: SeerRequestState {
        SeerRequestState(status: status)
    }

    var body: some View {
        if state == .requestable {
            Toggle(isOn: $isOn) {
                label
            }
        } else {
            HStack {
                label

                Spacer()

                Label(state.title, systemImage: state.systemImage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            #if !os(tvOS)
            .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
            #endif
        }
    }

    private var label: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(season.displayName)

            if let episodeCount = season.episodeCount {
                Text(episodeCount == 1 ? "1 episode" : "\(episodeCount) episodes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
