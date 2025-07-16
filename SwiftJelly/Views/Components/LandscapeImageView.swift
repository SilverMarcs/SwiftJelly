//
//  LandscapeImageView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import JellyfinAPI

struct LandscapeImageView: View {
    let item: BaseItemDto
    
    var body: some View {
        if let url = ImageURLProvider.landscapeImageURL(for: item) {
            CachedImageView(url: url, targetSize: CGSize(width: 1280, height: 720))
                .aspectRatio(16/9, contentMode: .fill)
        }
    }
}
