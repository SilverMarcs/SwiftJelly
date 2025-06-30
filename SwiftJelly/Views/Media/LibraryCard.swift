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
        AsyncImage(url: ImageURLProvider.landscapeImageURL(for: library, maxWidth: 400)) { image in
            image
                .resizable()
                .aspectRatio(16/9, contentMode: .fill)
        } placeholder: {
            RoundedRectangle(cornerRadius: 12)
                .overlay {
                    ProgressView()
                }
        }
        .aspectRatio(16/9, contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
