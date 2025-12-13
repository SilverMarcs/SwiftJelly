//
//  ProgressBarOverlay.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import SwiftUI
import JellyfinAPI

struct ProgressBarOverlay: View {
    let item: BaseItemDto
    var showSeasonNumber: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            ProgressIcon(isPlayed: item.userData?.isPlayed ?? false)
            
            ProgressGauge(progress: item.playbackProgress)
                .offset(y: 1)
            
            Text(item.totalDurationString ?? "--")
                .font(.subheadline)
            
            Spacer()
            
            if let episodeText = showSeasonNumber ? item.seasonEpisodeString : item.episodeOnlyString {
                Text(episodeText)
                    .font(.subheadline)
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
                .font(.subheadline)
                .foregroundStyle(.white, .accent)
        } else {
            Image(systemName: "play.fill")
                .font(.subheadline)
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
