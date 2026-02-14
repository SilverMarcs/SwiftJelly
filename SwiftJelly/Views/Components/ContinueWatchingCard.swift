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

    let item: BaseItemDto?
    let imageURLOverride: URL?

    #if os(tvOS)
    private let cardWidth: CGFloat = 420
    private let overlayHeight: CGFloat = 160
    private let overlayPadding: CGFloat = 25
    #else
    private let cardWidth: CGFloat = 230
    private let overlayHeight: CGFloat = 160
    private let overlayPadding: CGFloat = 15
    #endif
    
    private var cardHeight: CGFloat { cardWidth * 0.5625 } // 16:9 Aspect Ratio

    private let gradient = LinearGradient(
        gradient: Gradient(stops: [
            .init(color: .black.opacity(0.8), location: 0),
            .init(color: .black.opacity(0.7), location: 0.5),
            .init(color: .black.opacity(0), location: 1.0)
        ]),
        startPoint: .bottom,
        endPoint: .top
    )

    var body: some View {
        PlayMediaButton(item: item) {
            LandscapeImageView(item: item, imageURLOverride: imageURLOverride) {
                Image(systemName: "ellipsis")
                    .font(.title)
                    .opacity(0.5)
            }
            .frame(width: cardWidth, height: cardHeight, alignment: .center)
            .overlay(alignment: .bottomLeading) {
                if let item = item {
                    ProgressBarOverlay(item: item)
                        .padding(.horizontal, overlayPadding)
                        .padding(.vertical, overlayPadding - 5)
                        .background(alignment: .bottom) {
//                            Rectangle()
//                                .fill(.regularMaterial)
//                                .mask(gradient)
                            gradient
                        }
                }
            }
        }
        .environment(\.colorScheme, .dark)
        .foregroundStyle(.primary)
        .cardBorder()
        .adaptiveCardButtonStyle()
        .contextMenu {
            if let item = item {
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
}
