//
//  MediaCard.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import SwiftUI
import JellyfinAPI

struct MediaCard: View {
    @Environment(\.refresh) private var refresh
    let item: BaseItemDto
    
    var body: some View {
        LabelStack(alignment: .leading) {
            PortraitImageView(item: item)
                .cardBorder()
//                .blurredBottomOverlay()
                .overlay(alignment: .topTrailing) {
                    if item.userData?.isPlayed ?? false {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, .green)
                            .shadow(radius: 4)
                            .padding(12)
                    }
                }
                #if os(tvOS)
                .hoverEffect(.highlight)
                #endif
        }
    }
}
