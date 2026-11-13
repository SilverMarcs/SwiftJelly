//
//  SeasonEpisodeCard.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import JellyfinAPI

struct SeasonEpisodeCard: View {
    @Environment(\.refresh) var refresh
    let item: ViewListItem<BaseItemDto>
    var isPlayable = true

    var body: some View {
        if isPlayable {
            playableCard
        } else {
            SeasonEpisodeCardLabel(item: item.base) { episode in
                EpisodeAirDateOverlay(item: episode)
            }
            .foregroundStyle(.primary)
            .cardBorder(cornerRadius: 15)
        }
    }

    private var playableCard: some View {
        PlayMediaButton(item: item.base) {
            SeasonEpisodeCardLabel(item: item.base) { episode in
                ProgressBarOverlay(item: episode)
            }
        }
        .foregroundStyle(.primary)
        .cardBorder(cornerRadius: 15)
        .adaptiveCardButtonStyle()
        .contextMenu {
            if let episode = item.base {
                NavigationLink(value: NavigationRoute.media(episode)) {
                    Label("Go to Episode", systemImage: "play.rectangle")
                }

                Button {
                    Task {
                        try? await JFAPI.toggleItemPlayedStatus(item: episode)
                        await refresh()
                    }
                } label: {
                    Label(
                        episode.userData?.isPlayed == true ? "Mark as Unwatched" : "Mark as Watched",
                        systemImage: episode.userData?.isPlayed == true ? "eye.slash" : "eye"
                    )
                }
                
                Divider()
                
                #if os(iOS)
                EpisodeDownloadMenuItem(item: episode)
                #endif
            }
        }
    }
}

private struct EpisodeDownloadMenuItem: View {
    let item: BaseItemDto
    @State private var manager = DownloadManager.shared

    var body: some View {
        let record = manager.record(for: item.id)
        switch record?.status {
        case .completed:
            Button(role: .destructive) {
                if let id = item.id { manager.deleteDownload(for: id) }
            } label: {
                Label("Remove Download", systemImage: "trash")
            }
        case .downloading:
            Button(role: .destructive) {
                if let id = item.id { manager.cancelDownload(for: id) }
            } label: {
                Label("Cancel Download", systemImage: "xmark")
            }
        default:
            Button {
                manager.startDownload(for: item)
            } label: {
                Label("Download", systemImage: "arrow.down.to.line")
            }
        }
    }
}
