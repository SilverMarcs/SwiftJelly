//
//  ContinueWatchingCard.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import SwiftUI
import JellyfinAPI

struct ContinueWatchingCard: View {
    let item: BaseItemDto
    @EnvironmentObject private var dataManager: DataManager
    @State private var showPlayer = false
#if os(macOS)
    @Environment(\.openWindow) private var openWindow
#endif

    private var server: Server? {
        guard let currentUser = dataManager.currentUser else { return nil }
        return dataManager.servers.first { $0.id == currentUser.serverID }
    }
    
    private var user: User? {
        dataManager.currentUser
    }

    var body: some View {
        Button {
#if os(macOS)
            if let server, let user {
                let data = ContinueWatchingPlayerWindowData(item: item, serverId: server.id, userId: user.id)
                openWindow(id: "continue-watching-player", value: data)
            }
#else
            showPlayer = true
#endif
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: primaryImageURL) { image in
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

                    if let season = item.parentIndexNumber, let episode = item.indexNumber {
                        Text("S\(season)E\(episode)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
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

    private var primaryImageURL: URL? {
        guard let server = server,
              let user = user,
              let client = dataManager.jellyfinClient(for: user, server: server),
              let id = item.id else { return nil }

        // Use proper Jellyfin API image URL generation like the old project
        let maxWidth: CGFloat = 600

        // For episodes, try to get landscape images (thumb/backdrop) from series
        if item.type == .episode, let seriesId = item.seriesID {
            // Try thumb image from series first
            if let thumbTag = getImageTag(for: .thumb, from: item) {
                let parameters = Paths.GetItemImageParameters(
                    maxWidth: Int(maxWidth),
                    tag: thumbTag
                )
                let request = Paths.getItemImage(
                    itemID: seriesId,
                    imageType: ImageType.thumb.rawValue,
                    parameters: parameters
                )
                return client.fullURL(with: request)
            }

            // Try backdrop image from series
            if let backdropTag = item.backdropImageTags?.first {
                let parameters = Paths.GetItemImageParameters(
                    maxWidth: Int(maxWidth),
                    tag: backdropTag
                )
                let request = Paths.getItemImage(
                    itemID: seriesId,
                    imageType: ImageType.backdrop.rawValue,
                    parameters: parameters
                )
                return client.fullURL(with: request)
            }
        }

        // For other items or fallback, try thumb first, then backdrop, then primary
        if let thumbTag = getImageTag(for: .thumb, from: item) {
            let parameters = Paths.GetItemImageParameters(
                maxWidth: Int(maxWidth),
                tag: thumbTag
            )
            let request = Paths.getItemImage(
                itemID: id,
                imageType: ImageType.thumb.rawValue,
                parameters: parameters
            )
            return client.fullURL(with: request)
        }

        if let backdropTag = item.backdropImageTags?.first {
            let parameters = Paths.GetItemImageParameters(
                maxWidth: Int(maxWidth),
                tag: backdropTag
            )
            let request = Paths.getItemImage(
                itemID: id,
                imageType: ImageType.backdrop.rawValue,
                parameters: parameters
            )
            return client.fullURL(with: request)
        }

        if let primaryTag = getImageTag(for: .primary, from: item) {
            let parameters = Paths.GetItemImageParameters(
                maxWidth: Int(maxWidth),
                tag: primaryTag
            )
            let request = Paths.getItemImage(
                itemID: id,
                imageType: ImageType.primary.rawValue,
                parameters: parameters
            )
            return client.fullURL(with: request)
        }

        return nil
    }

    private func getImageTag(for type: ImageType, from item: BaseItemDto) -> String? {
        switch type {
        case .backdrop:
            return item.backdropImageTags?.first
        case .screenshot:
            return item.screenshotImageTags?.first
        default:
            return item.imageTags?[type.rawValue]
        }
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
