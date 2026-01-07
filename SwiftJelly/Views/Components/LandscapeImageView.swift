//
//  LandscapeImageView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct LandscapeImageView: View {
    let item: BaseItemDto
    
    var body: some View {
        if let url = imageURL {
            CachedAsyncImage(url: url, targetSize: 1500)
                .aspectRatio(16/9, contentMode: .fill)
        }
    }

    private var imageURL: URL? {
        ImageURLProvider.imageURL(for: item, type: .thumb)
            ?? ImageURLProvider.imageURL(for: item, type: .backdrop)
            ?? ImageURLProvider.imageURL(for: item, type: .primary)
    }
}
