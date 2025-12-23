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
    
    #if os(tvOS)
    private let cornerRadius: CGFloat = 20
    #else
    private let cornerRadius: CGFloat = 13
    #endif
    
    var body: some View {
        tvOSCard
    }
    
    private var tvOSCard: some View {
        PortraitImageView(item: item)
            .aspectRatio(2/3, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .clipped()
            .overlay(alignment: .topTrailing) {
                if item.userData?.isPlayed ?? false {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white, .green)
                        .shadow(radius: 4)
                        .padding(12)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.gray.opacity(0.5), lineWidth: 1)
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
        
            #if !os(macOS)
            .hoverEffect(.highlight)
            #endif
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
            .buttonBorderShape(.roundedRectangle(radius: cornerRadius))
    }
}
