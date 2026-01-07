//
//  ContinueWatchingCard.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import JellyfinAPI

struct ContinueWatchingCard: View {
    @Environment(\.refresh) var refresh
    @Environment(\.isInSeasonView) private var isInSeasonView

    let item: BaseItemDto
    let imageURLOverride: URL?

    #if os(tvOS)
    private let cardWidth: CGFloat = 550
    private let cardHeight: CGFloat = 333
    private let overlayPadding: CGFloat = 30
    #else
    private let cardWidth: CGFloat = 300
    private let cardHeight: CGFloat = 200
    private let overlayPadding: CGFloat = 15
    #endif

    private let gradient = LinearGradient(
        gradient: Gradient(stops: [
            .init(color: .white, location: 0),
            .init(color: .white.opacity(0.7), location: 0.15),
            .init(color: .white.opacity(0), location: 0.25)
        ]),
        startPoint: .bottom,
        endPoint: .top
    )

    var body: some View {
        PlayMediaButton(item: item) {
            LandscapeImageView(item: item, imageURLOverride: imageURLOverride)
                .scaledToFill()
                .frame(width: cardWidth, height: cardHeight, alignment: .top)
                .clipped()
                .overlay {
                    Rectangle()
                        .fill(.ultraThickMaterial)
                        .mask(gradient)
                }
                .overlay(alignment: .bottomLeading) {
                    ProgressBarOverlay(item: item)
                        .padding(.horizontal, overlayPadding)
                        .padding(.vertical, overlayPadding - 2)
                }
                .environment(\.colorScheme, .dark)
                #if !os(macOS)
                .hoverEffect(.highlight)
                #endif
        }
        .foregroundStyle(.primary)
        .cardBorder()
        .adaptiveButtonStyle()
        .contextMenu {
            if !isInSeasonView {
                Section {
                    MediaNavigationLink(item: item) {
                        PlayableItemTypeLabel(item: item)
                    }
                }
            }

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
