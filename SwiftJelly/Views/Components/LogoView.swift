//
//  LogoView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 23/09/2025.
//

import SwiftUI
import JellyfinAPI
import CachedAsyncImage

struct LogoView: View {
    let item: BaseItemDto
    
    var body: some View {
        if let logoURL = ImageURLProvider.logoImageURL(for: item) {
            CachedAsyncImage(url: logoURL, targetSize: CGSize(width: 300, height: 300))
                .frame(maxWidth: 250, maxHeight: 100)
        } else {
            titleText
        }
    }
    
    private var titleText: some View {
        Text(item.name ?? "Unknown")
            .font(.largeTitle.weight(.semibold))
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .foregroundColor(.white)
            .frame(height: 100, alignment: .bottom)
    }
}
