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
        AsyncImage(url: ImageURLProvider.landscapeImageURL(for: item)) { image in
            image
                .resizable()
                .aspectRatio(16/9, contentMode: .fill)
        } placeholder: {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
