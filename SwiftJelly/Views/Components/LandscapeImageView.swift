//
//  LandscapeImageView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import JellyfinAPI
import Kingfisher

struct LandscapeImageView: View {
    let item: BaseItemDto
    
    var body: some View {
        KFImage(ImageURLProvider.landscapeImageURL(for: item))
            .placeholder {
                Rectangle()
                    .fill(.background.secondary)
                    .overlay {
                        ProgressView()
                    }
            }
            .resizable()
            .aspectRatio(16/9, contentMode: .fill)
    }
}
