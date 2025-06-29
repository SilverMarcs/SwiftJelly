//
//  PlayableCard.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import SwiftUI
import JellyfinAPI

struct PlayableCard: View {
    let item: BaseItemDto
    @State private var showPlayer = false
#if os(macOS)
    @Environment(\.openWindow) private var openWindow
#endif

    var body: some View {
        Button {
#if os(macOS)
            openWindow(id: "media-player", value: item)
#else
            showPlayer = true
#endif
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: ImageURLProvider.landscapeImageURL(for: item)) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: 270, height: 168)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .bottom) {
                    ProgressBarOverlay(
                        title: progressLabel,
                        progress: progressPercentage ?? 0
                    )
                }

                HStack(alignment: .top) {
                // Title and Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name ?? "Unknown")
                            .font(.headline)
                            .lineLimit(1)
                        
                        if let parentTitle = item.seriesName ?? item.album ?? item.parentID {
                            Text(parentTitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    if let season = item.parentIndexNumber, let episode = item.indexNumber {
                        Text("S\(season)E\(episode)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 270)
        }
        .buttonStyle(.plain)
#if !os(macOS)
        .sheet(isPresented: $showPlayer) {
            // TODO: Implement playback using BaseItemDto props and your player logic
            Text("Playback not implemented for BaseItemDto yet.")
                .padding()
        }
#endif
    }



    private var progressLabel: String {
        if let played = item.userData?.isPlayed, played {
            return "Played"
        }

        // Show time remaining like the old project
        if let playbackPositionTicks = item.userData?.playbackPositionTicks,
           let totalTicks = item.runTimeTicks,
           playbackPositionTicks > 0,
           totalTicks > 0 {

            let remainingSeconds = (totalTicks - playbackPositionTicks) / 10_000_000
            return formatTimeRemaining(Int(remainingSeconds))
        }

        return "Start"
    }

    private func formatTimeRemaining(_ seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated

        if let formattedTime = formatter.string(from: TimeInterval(seconds)) {
            return formattedTime
        }

        // Fallback formatting
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private var progressPercentage: Double? {
        guard let ticks = item.userData?.playbackPositionTicks, let runtime = item.runTimeTicks, runtime > 0 else { return nil }
        return Double(ticks) / Double(runtime)
    }
}
