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
        VStack(alignment: .leading, spacing: 8) {
            PortraitImageView(item: item)
                .aspectRatio(2/3, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.background.quinary, lineWidth: 1)
                }
                .overlay(alignment: .topTrailing) {
                    HStack(spacing: 4) {
                        if item.userData?.isFavorite == true {
                            Button {} label: {
                                Image(systemName: "star.fill")
                                    .imageScale(.small)
                            }
                            .tint(.orange)
                            .buttonStyle(.glassProminent)
                            .buttonBorderShape(.circle)
                            .allowsHitTesting(false)
                        }
                        
                        if item.userData?.isPlayed ?? false {
                            Button {} label: {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                            }
                            .buttonStyle(.glassProminent)
                            .buttonBorderShape(.circle)
                            .allowsHitTesting(false)
                        }
                    }
                    .padding(6)
                }
            
            Text(item.name ?? "Unknown")
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)
                .multilineTextAlignment(.leading)
        }
        .contentShape(.rect)
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
    }
}
