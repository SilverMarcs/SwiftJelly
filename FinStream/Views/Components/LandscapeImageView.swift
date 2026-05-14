//
//  LandscapeImageView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct LandscapeImageView<Placeholder: View>: View {
    let item: BaseItemDto?
    var imageURLOverride: URL? = nil
    let placeholder: () -> Placeholder
    
    public init(
        item: BaseItemDto?,
        imageURLOverride: URL? = nil,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.item = item
        self.imageURLOverride = imageURLOverride
        self.placeholder = placeholder
    }

    // Default placeholder
    public init(item: BaseItemDto?, imageURLOverride: URL? = nil) where Placeholder == EmptyView {
        self.item = item
        self.imageURLOverride = imageURLOverride
        self.placeholder = { EmptyView() }
    }
    
    var body: some View {
        CachedAsyncImage(url: imageURLOverride ?? imageURL, targetSize: 600, placeholder: placeholder)
            .aspectRatio(16/9, contentMode: .fill)
    }


    private var imageURL: URL? {
        if let item {
            ImageURLProvider.imageURL(for: item, type: .thumb)
                ?? ImageURLProvider.imageURL(for: item, type: .backdrop)
                ?? ImageURLProvider.imageURL(for: item, type: .primary)
        } else {
            nil
        }
    }
}
