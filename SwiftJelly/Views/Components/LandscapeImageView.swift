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
        CachedAsyncImage(url: ImageURLProvider.imageURL(for: item, type: .thumb), targetSize: 1500)
            .aspectRatio(16/9, contentMode: .fill)
    }
}
