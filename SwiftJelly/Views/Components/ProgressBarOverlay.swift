//
//  ProgressBarOverlay.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import SwiftUI
import JellyfinAPI

struct ProgressBarOverlay: View {
    @Environment(\.isInSeasonView) private var isInSeasonView
    
    let item: BaseItemDto
    var showEpisodeInformation: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            ProgressIcon(isPlayed: item.userData?.isPlayed ?? false)
            
            ProgressGauge(progress: item.playbackProgress)
                .offset(y: 1)
            
            Text(item.totalDurationString ?? "--")
                .font(.caption2)
            
            Spacer()
            
            if showEpisodeInformation, let episodeText = isInSeasonView ? item.episodeOnlyString : item.seasonEpisodeString {
                Text(episodeText)
                    .font(.caption2)
            }
        }
        .foregroundStyle(.white)
    }
}

struct ProgressIcon: View {
    let isPlayed: Bool
    
    var body: some View {
        if isPlayed {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(.white, .accent)
        } else {
            Image(systemName: "play.fill")
                .font(.caption2)
                .foregroundStyle(.white)
        }
    }
}

struct ProgressGauge: View {
    let progress: Double?
    var body: some View {
        if let progress, progress > 0, progress < 1 {
            ProgressView(value: progress)
                #if os(tvOS)
//                .tint(.primary)
                .frame(width: 100)
                #else
                .controlSize(.mini)
                .frame(width: 60)
                #endif
        }
    }
}


#Preview {
    ProgressBarOverlay(item: BaseItemDto(indexNumber: 12, parentIndexNumber: 5, runTimeTicks: 30000, userData: UserItemDataDto(playbackPositionTicks: 1300, isPlayed: true)))
}
