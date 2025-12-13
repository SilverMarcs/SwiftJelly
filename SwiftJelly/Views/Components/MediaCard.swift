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
                #if !os(tvOS)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.background.quinary, lineWidth: 1)
                }
                #endif
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
                #if os(tvOS)
                .hoverEffect(.highlight)
                #endif
            
            Text(item.name ?? "Unknown")
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)
                .multilineTextAlignment(.leading)
                .padding(.leading, 1)
        }
    }
}
