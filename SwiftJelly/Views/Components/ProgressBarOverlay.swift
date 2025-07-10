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
            Text(item.totalDurationString ?? "--")
                .font(.subheadline)
            Spacer()
        }
        .foregroundStyle(.white)
    }
}

private struct ProgressIcon: View {
    let isPlayed: Bool
    var body: some View {
        Image(systemName: isPlayed ? "checkmark.circle.fill" : "play.fill")
            .font(.subheadline)
            .foregroundStyle(isPlayed ? .accent : .white)
    }
}

private struct ProgressGauge: View {
    let progress: Double?
    var body: some View {
        if let progress, progress > 0, progress < 1 {
            Gauge(value: progress) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            } minimumValueLabel: {
                EmptyView()
            } maximumValueLabel: {
                EmptyView()
            }
            .gaugeStyle(.accessoryLinearCapacity)
            .frame(width: 60)
        }
    }
}
