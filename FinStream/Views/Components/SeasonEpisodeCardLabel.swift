//
//  SeasonEpisodeCardLabel.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

#if !os(tvOS)
import SwiftUI
import JellyfinAPI

struct SeasonEpisodeCardLabel<Footer: View>: View {
    let item: BaseItemDto?
    @ViewBuilder let footer: (BaseItemDto) -> Footer

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
        LandscapeImageView(item: item) {
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
                Text(item?.name ?? "")
                    .foregroundStyle(.white)
                    .font(.subheadline)
                    .bold()
                    .lineLimit(1)
                    .padding(.top, 20)
                    .truncationMode(.middle)
                    .multilineTextAlignment(.leading)

                if let overview = item?.overview, !overview.isEmpty {
                    Text(overview)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.footnote)
                        .opacity(0.9)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3, reservesSpace: true)
                }

                if let item {
                    footer(item)
                        .padding(.top, 5)
                }
            }
            .padding(.horizontal, overlayPadding)
            .padding(.vertical, overlayPadding - 5)
            .background {
                if item != nil {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .mask(largeGradient)
                }
            }
        }
    }

    private var cardWidth: CGFloat { 230 }

    private var cardHeight: CGFloat { 230 }

    private var overlayPadding: CGFloat { 15 }
}
#endif
