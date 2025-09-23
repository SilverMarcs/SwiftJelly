//
//  LandscapeImageView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import JellyfinAPI
import CachedAsyncImage

struct LandscapeImageView: View {
    let item: BaseItemDto
    
    var body: some View {
        CachedAsyncImage(url: ImageURLProvider.imageURL(for: item, type: .thumb), targetSize: CGSize(width: 1280, height: 720))
            .aspectRatio(16/9, contentMode: .fill)
    }
}
