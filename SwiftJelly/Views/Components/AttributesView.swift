//
//  AttributesView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 21/09/2025.
//

import SwiftUI
import JellyfinAPI

struct AttributesView: View {
    let item: BaseItemDto
    
    var body: some View {
        HStack(spacing: 10) {
            if let genre = item.genres?.first {
                AttributeBadge(
                    text: genre,
                )
            }
            
            // Community Rating (stars)
            if let communityRating = item.communityRating {
                unsafe AttributeBadge(
                    text: String(format: "%.1f", communityRating),
                    systemImage: "star.fill",
                )
            }
            
            // Critic Rating (tomato)
            if let criticRating = item.criticRating {
                unsafe AttributeBadge(
                    text: String(format: "%.0f", criticRating),
                    systemImage: criticRating >= 60 ? "checkmark.seal.fill" : "xmark.seal.fill",
                )
            }
            
            // Year
            if let year = item.productionYear {
                AttributeBadge(text: String(year), systemImage: "calendar")
            }
            
            // Runtime (dont show for shows
            if let runTimeTicks = item.runTimeTicks, item.type != .series {
                let minutes = runTimeTicks / 10_000_000 / 60
                AttributeBadge(text: "\(minutes)m", systemImage: "clock")
            }
        }
    }
}

struct AttributeBadge: View {
    let text: String
    let systemImage: String?
    
    init(text: String, systemImage: String? = nil) {
        self.text = text
        self.systemImage = systemImage
    }
    
    var body: some View {
        Label {
            Text(text)
        } icon: {
            if let systemImage = systemImage {
                Image(systemName: systemImage)
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .glassEffect(in: .rect(cornerRadius: 6))
    }
}
