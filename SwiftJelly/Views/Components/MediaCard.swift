//
//  MediaCard.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import SwiftUI
import JellyfinAPI

struct MediaCard: View {
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
                    if item.userData?.isPlayed ?? false {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.white, .accent)
                            .padding(.top, 6)
                            .padding(.horizontal, 8)
                    }
                }
            
            Text(item.name ?? "Unknown")
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)
                .multilineTextAlignment(.leading)
        }
    }
}
