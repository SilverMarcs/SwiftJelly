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
            AsyncImage(url: ImageURLProvider.portraitImageURL(for: item)) { image in
                image
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(2/3, contentMode: .fit)
                    .overlay {
                        Image(systemName: iconName)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name ?? "Unknown")
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let year = item.productionYear {
                    Text("\(year)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                if let overview = item.overview, !overview.isEmpty {
                    Text(overview)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                }
            }
        }
    }
    
    private var iconName: String {
        switch item.type {
        case .movie:
            return "film"
        case .series:
            return "tv"
        case .episode:
            return "tv"
        case .musicAlbum:
            return "music.note"
        case .book:
            return "book"
        case .photo:
            return "photo"
        default:
            return "questionmark"
        }
    }
}
//
//#Preview {
//    let sampleItem = BaseItemDto(
//        id: "sample-id", name: "Sample Movie",
//        type: .movie,
//        productionYear: 2023,
//        overview: "This is a sample movie description that shows how the card looks with text."
//    )
//    
//    MediaCard(item: sampleItem)
//        .frame(width: 120)
//        .padding()
//}
