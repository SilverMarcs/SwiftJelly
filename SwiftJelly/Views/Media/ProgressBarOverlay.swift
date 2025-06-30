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
            if item.userData?.isPlayed == true {
                Image(systemName: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                if let progress = progressPercentage, progress > 0, progress < 1 {
                    ProgressView(value: progress)
                        .controlSize(.small)
                        .frame(width: 60)
                }
                Text(item.runTimeTicks != nil ? formatDuration(item.runTimeTicks!) : "--")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            } else {
                Image(systemName: "play.fill")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                
                if let progress = progressPercentage, progress > 0, progress < 1 {
                    ProgressView(value: progress)
                        .controlSize(.small)
                        .frame(width: 60)
                }
                
                Text(item.runTimeTicks != nil ? formatDuration(item.runTimeTicks!) : "--")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
    }
    
    private func formatDuration(_ ticks: Int) -> String {
        let seconds = ticks / 10_000_000
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval(seconds)) ?? "--"
    }

    private var progressPercentage: Double? {
        guard let ticks = item.userData?.playbackPositionTicks, let runtime = item.runTimeTicks, runtime > 0 else { return nil }
        let percent = Double(ticks) / Double(runtime)
        return percent > 1 ? 1 : percent
    }
}
