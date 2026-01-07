//
//  SeasonEpisodeCard.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import JellyfinAPI

struct SeasonEpisodeCard: View {
    let item: BaseItemDto

    #if os(tvOS)
    private let cardWidth: CGFloat = 550
    private let cardHeight: CGFloat = 333
    private let reflectionHeight: CGFloat = 150
    private let overlayPadding: CGFloat = 30
    #else
    private let cardWidth: CGFloat = 300
    private let cardHeight: CGFloat = 200
    private let reflectionHeight: CGFloat = 50
    private let overlayPadding: CGFloat = 15
    #endif

    private let largeGradient = LinearGradient(
        gradient: Gradient(stops: [
            .init(color: .white, location: 0),
            .init(color: .white, location: 0.2),
            .init(color: .white.opacity(0.9), location: 0.3),
            .init(color: .white.opacity(0), location: 0.5),
            .init(color: .white.opacity(0), location: 1.0)
        ]),
        startPoint: .bottom,
        endPoint: .top
    )

    private var totalHeight: CGFloat {
        cardHeight + reflectionHeight
    }

    var body: some View {
        PlayMediaButton(item: item) {
            LandscapeImageView(item: item)
                .scaledToFill()
                .frame(width: cardWidth, height: totalHeight, alignment: .top)
                .clipped()
                .overlay {
                    Rectangle()
                        .fill(.regularMaterial)
                        .mask(largeGradient)
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.name ?? "Unknown")
                            .foregroundStyle(.white)
                            .bold()
                            .opacity(0.7)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .multilineTextAlignment(.leading)

                        if let overview = item.overview, !overview.isEmpty {
                            Text(overview)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.caption2)
                                .opacity(0.5)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3, reservesSpace: false)
                        }

                        ProgressBarOverlay(item: item)
                    }
                    .padding(.horizontal, overlayPadding)
                    .padding(.vertical, overlayPadding - 2)
                }
                .environment(\.colorScheme, .dark)
        }
        .foregroundStyle(.primary)
        .cardBorder()
        .adaptiveButtonStyle()
    }
}
