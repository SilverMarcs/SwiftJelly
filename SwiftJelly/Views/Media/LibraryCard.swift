//
//  LibraryCard.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import SwiftUI
import JellyfinAPI
import Get

struct LibraryCard: View {
    let library: BaseItemDto
    // No longer need DataManager or server/user logic here
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: ImageURLProvider.portraitImageURL(for: library, maxWidth: 300)) { image in
                image
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: iconName)
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(width: 150, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(library.name ?? "Unknown Library")
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(width: 150)
    }
    
    // No longer need primaryImageURL or getImageTag, handled by ImageURLProvider
    
    private var iconName: String {
        switch library.collectionType {
        case .movies:
            return "film"
        case .tvshows:
            return "tv"
        case .music:
            return "music.note"
        case .books:
            return "book"
        case .photos:
            return "photo"
        default:
            return "folder"
        }
    }
}
