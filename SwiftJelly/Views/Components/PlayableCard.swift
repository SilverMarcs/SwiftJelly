//
//  PlayableCard.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import SwiftUI
import JellyfinAPI

struct PlayableCard: View {
    let item: BaseItemDto
    @State private var showPlayer = false

    var body: some View {
        PlayMediaButton(item: item) {
            VStack(alignment: .leading, spacing: 8) {
                LandscapeImageView(item: item)
                    .frame(width: 270, height: 168)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(alignment: .bottom) {
                        ZStack(alignment: .bottom) {
                            // Subtle black-to-transparent gradient for blending
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black.opacity(0.9), Color.clear]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            .frame(height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            
                            ProgressBarOverlay(item: item)
                                .padding(.bottom, 6)
                                .padding(.horizontal, 8)
                        }
                    }

                HStack(alignment: .top) {
                    if let parentTitle = item.seriesName ?? item.album {
                        Text(parentTitle)
                            .font(.subheadline)
                            .lineLimit(1)
                    } else {
                        Text(item.name ?? "Unknown")
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                        
                    if let season = item.parentIndexNumber, let episode = item.indexNumber {
                        Text("S\(season)E\(episode)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 5)
            }
            .frame(width: 270)
        }
        .buttonStyle(.plain)
    }
}
