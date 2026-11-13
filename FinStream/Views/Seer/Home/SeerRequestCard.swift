//
//  SeerRequestCard.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI
import JellyfinAPI

struct SeerRequestCard: View {
    let requestItem: SeerRequestItem?

    var body: some View {
        MediaNavigationLink(item: requestItem?.item) {
            LandscapeImageView(item: requestItem?.item) {
                Image(systemName: "ellipsis")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
            .frame(width: cardWidth, height: cardHeight, alignment: .center)
            .background(.background.secondary)
            .overlay(alignment: .bottomLeading) {
                if let requestItem {
                    overlay(for: requestItem)
                }
            }
            .cardBorder()
        }
    }

    private func overlay(for requestItem: SeerRequestItem) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text(requestItem.item.name ?? "")
                .font(.caption)
                .bold()
                .foregroundStyle(.white)
                .lineLimit(1)
                .layoutPriority(-1)

            Spacer(minLength: 0)

            SeerRequestStatusBadge(status: requestItem.request.displayStatus, downloadProgress: requestItem.request.media.downloadProgress)
        }
        .padding(.horizontal, overlayPadding)
        .padding(.vertical, overlayPadding - 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [.clear, .black.opacity(0.7), .black.opacity(0.9)], startPoint: .top, endPoint: .bottom))
    }

    private var cardWidth: CGFloat {
        #if os(tvOS)
        420
        #else
        Device.isMacOrPad ? 300 : 250
        #endif
    }

    private var cardHeight: CGFloat { cardWidth * 0.5625 }

    private var overlayPadding: CGFloat {
        #if os(tvOS)
        25
        #else
        15
        #endif
    }
}
