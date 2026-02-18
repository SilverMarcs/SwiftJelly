//
//  SeasonEpisodeCard.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import JellyfinAPI

#if !os(tvOS)

struct SeasonEpisodeCard: View {
    @Environment(\.refresh) var refresh
    let item: ViewListItem<BaseItemDto>

    #if os(tvOS)
    private let cardWidth: CGFloat = 550
    private let cardHeight: CGFloat = 483
    private let overlayPadding: CGFloat = 30
    #else
    private let cardWidth: CGFloat = 230
    private let cardHeight: CGFloat = 230
    private let overlayPadding: CGFloat = 15
    #endif

    private let largeGradient = LinearGradient(
        gradient: Gradient(stops: [
            .init(color: .white, location: 0),
            .init(color: .white.opacity(0.9), location: 0.8),
            .init(color: .white.opacity(0), location: 1.0)
        ]),
        startPoint: .bottom,
        endPoint: .top
    )

    var body: some View {
        PlayMediaButton(item: item.base) {
            LandscapeImageView(item: item.base) {
                Image(systemName: "ellipsis")
                    .font(.title)
                    .frame(width: cardWidth, height: cardHeight, alignment: .center)
                    .foregroundStyle(.secondary)
            }
            .scaledToFill()
            .frame(width: cardWidth, height: cardHeight, alignment: .top)
            .background(.background.secondary)
            .clipped()
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.base?.name ?? "")
                        .foregroundStyle(.white)
                        .font(.subheadline)
                        .bold()
                        .lineLimit(1)
                        .padding(.top, 20)
                        .truncationMode(.middle)
                        .multilineTextAlignment(.leading)

                    if let overview = item.base?.overview, !overview.isEmpty {
                        Text(overview)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.footnote)
                            .opacity(0.9)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3, reservesSpace: true)
                    }

                    if let episodeItem = item.base {
                        ProgressBarOverlay(item: episodeItem)
                            .padding(.top, 5)
                    }
                }
                .padding(.horizontal, overlayPadding)
                .padding(.vertical, overlayPadding - 5)
                
                .background {
                    if item.base != nil {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .mask(largeGradient)
                    }
                }
            }
            .environment(\.colorScheme, .dark)
        }
        .foregroundStyle(.primary)
        .cardBorder(cornerRadius: 15)
        .adaptiveButtonStyle()
        .contextMenu {
            if let item = item.base {
                Button {
                    Task {
                        try? await JFAPI.toggleItemPlayedStatus(item: item)
                        await refresh()
                    }
                } label: {
                    Label(
                        item.userData?.isPlayed == true ? "Mark as Unwatched" : "Mark as Watched",
                        systemImage: item.userData?.isPlayed == true ? "eye.slash" : "eye"
                    )
                }
            }
        }
    }
}

#endif
