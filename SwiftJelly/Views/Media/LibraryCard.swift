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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: ImageURLProvider.portraitImageURL(for: library, maxWidth: 300)) { image in
                image
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .overlay {
                        ProgressView()
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
}
