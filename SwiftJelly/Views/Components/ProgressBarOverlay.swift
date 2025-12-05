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

    var body: some View {
        HStack(spacing: 12) {
            ProgressIcon(isPlayed: item.userData?.isPlayed ?? false)
            
            ProgressGauge(progress: item.playbackProgress)
                .offset(y: 1)
            
            Text(item.totalDurationString ?? "--")
                .font(.subheadline)
            
            Spacer()
            
            if let seasonEpisode = item.seasonEpisodeString {
                Text(seasonEpisode)
                    .font(.subheadline)
            }
        }
        .foregroundStyle(.white)
    }
}

struct ProgressIcon: View {
    let isPlayed: Bool
    var body: some View {
        // TODO: use glass button here
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
            #if os(tvOS)
            ProgressView(value: progress)
                .tint(.primary)
                .frame(width: 100)
            #else
            Gauge(value: progress) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            } minimumValueLabel: {
                EmptyView()
            } maximumValueLabel: {
                EmptyView()
            }
            .controlSize(.mini)
            .gaugeStyle(.accessoryLinearCapacity)
            .frame(width: 60)
            #endif
        }
    }
}
