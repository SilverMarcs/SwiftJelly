//
//  ContinueWatchingView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import VLCUI

struct ContinueWatchingView: View {
    @StateObject private var continueWatchingManager = ContinueWatchingManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Continue Watching")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if continueWatchingManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal)
            
            if let error = continueWatchingManager.error {
                Text("Error: \(error)")
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            if continueWatchingManager.items.isEmpty && !continueWatchingManager.isLoading {
                VStack(spacing: 8) {
                    Image(systemName: "tv.slash")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    
                    Text("No items to continue watching")
                        .foregroundStyle(.secondary)
                        .font(.headline)
                    
                    Text("Start watching something to see it here")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(continueWatchingManager.items) { item in
                            ContinueWatchingCard(item: item)
                                .contextMenu {
                                    Button {
                                        Task {
                                            await continueWatchingManager.markAsPlayed(item)
                                        }
                                    } label: {
                                        Label("Mark as Played", systemImage: "checkmark.circle")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 200)
            }
        }
        .task {
            await continueWatchingManager.loadContinueWatching()
        }
        .refreshable {
            await continueWatchingManager.loadContinueWatching()
        }
    }
}

struct ContinueWatchingCard: View {
    let item: MediaItem
    @EnvironmentObject private var dataManager: DataManager
    @State private var showPlayer = false

    private var server: Server? {
        guard let currentUser = dataManager.currentUser else { return nil }
        return dataManager.servers.first { $0.id == currentUser.serverID }
    }
    private var user: User? {
        dataManager.currentUser
    }

    var body: some View {
        Button {
            showPlayer = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Landscape Image with Progress Bar
                ZStack(alignment: .bottom) {
                    AsyncImage(url: landscapeImageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fill)
                            .overlay {
                                VStack(spacing: 8) {
                                    Image(systemName: "tv")
                                        .font(.system(size: 30))
                                        .foregroundStyle(.secondary)
                                    Text(item.displayTitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }
                                .padding()
                            }
                    }
                    .frame(width: 300, height: 168)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Progress Bar Overlay
                    VStack {
                        Spacer()
                        ProgressBarOverlay(
                            title: item.progressLabel ?? "Continue",
                            progress: item.progressPercentage
                        )
                    }
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
        .sheet(isPresented: $showPlayer) {
            if let server, let user, let url = item.playbackURL(for: server, user: user) {
                VLCVideoPlayer(
                    configuration: .init(
                        url: url,
                        autoPlay: true,
                        startSeconds: .seconds(Int64(item.startTimeSeconds)))
//                    ),
//                    proxy: nil,
//                    onTicksUpdated: { _, _ in },
//                    onStateUpdated: { _, _ in },
//                    loggingInfo: nil
                )
            } else {
                Text("Unable to play this item.")
                    .padding()
            }
        }
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

struct ProgressBarOverlay: View {
    let title: String
    let progress: Double
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                
                Spacer()
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: geometry.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
