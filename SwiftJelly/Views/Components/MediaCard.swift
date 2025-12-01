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
        #if os(tvOS)
        tvOSCard
        #else
        standardCard
        #endif
    }
    
    #if os(tvOS)
    private var tvOSCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            PortraitImageView(item: item)
                .aspectRatio(2/3, contentMode: .fill)
                .overlay(alignment: .topTrailing) {
                    if item.userData?.isPlayed ?? false {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, .green)
                            .shadow(radius: 4)
                            .padding(12)
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    if item.userData?.isFavorite == true {
                        Image(systemName: "star.fill")
                            .font(.subheadline)
                            .foregroundStyle(.yellow)
                            .shadow(radius: 4)
                            .padding(12)
                    }
                }
        }
    }
    #endif
    
    private var standardCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            PortraitImageView(item: item)
                .aspectRatio(2/3, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.background.quinary, lineWidth: 1)
                }
                #if !os(tvOS)
                .overlay(alignment: .topTrailing) {
                    if item.userData?.isPlayed ?? false {
                        Button {} label: {
                            Image(systemName: "checkmark")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.glassProminent)
                        .controlSize(.small)
                        .buttonBorderShape(.circle)
                        .allowsHitTesting(false)
                        .padding(6)
                    }
                }
                #endif
            
            Text(item.name ?? "Unknown")
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)
                .multilineTextAlignment(.leading)
        }
        .contentShape(.rect)
        #if !os(tvOS)
        .contextMenu {
            if item.type == .movie || item.type == .series {
                Button {
                    Task {
                        try? await JFAPI.toggleItemFavoriteStatus(item: item)
                        await refresh()
                    }
                } label: {
                    Label(item.userData?.isFavorite == true ? "Remove Favorite" : "Add to Favorites",
                          systemImage: item.userData?.isFavorite == true ? "star.slash" : "star")
                }
            }
        }
        #endif
    }
}
