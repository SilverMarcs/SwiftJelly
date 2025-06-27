//
//  ContinueWatchingCard.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import SwiftUI

struct ContinueWatchingCard: View {
    let item: MediaItem
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
                AsyncImage(url: landscapeImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: 300, height: 168)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .bottom) {
                    ProgressBarOverlay(
                        title: item.progressLabel ?? "Continue",
                        progress: item.progressPercentage
                    )
                }

                // Title and Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayTitle)
                        .font(.headline)
                        .lineLimit(1)

                    if let parentTitle = item.parentTitle {
                        Text(parentTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if let seasonEpisodeLabel = item.seasonEpisodeLabel {
                        Text(seasonEpisodeLabel)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .frame(width: 300)
        }
        .buttonStyle(.plain)
#if !os(macOS)
        .sheet(isPresented: $showPlayer) {
            if let server, let user, let url = item.playbackURL(for: server, user: user) {
                VLCVideoPlayer(
                    configuration: .init(
                        url: url,
                        autoPlay: true,
                        startSeconds: .seconds(Int64(item.startTimeSeconds))
                    )
                )
            } else {
                Text("Unable to play this item.")
                    .padding()
            }
        }
#endif
    }

    private var landscapeImageURL: URL? {
        guard let server = server else { return nil }

        // Try thumb first (landscape), then backdrop, then primary
        let imageTypes: [ImageType] = [.thumb, .backdrop, .primary]

        for imageType in imageTypes {
            if let url = item.imageURL(for: server, type: imageType, maxWidth: 600) {
                return url
            }
        }

        return nil
    }
}
