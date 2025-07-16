//
//  CachedImage.swift
//  SwiftReddit
//
//  Created by Zabir Raihan on 16/07/2025.
//

import SwiftUI

struct CachedImageView: View {
    private var loader: ImageLoader?
    #if os(macOS)
    @State private var image: NSImage?
    #else
    @State private var image: UIImage?
    #endif
    
    init(url: URL?, targetSize: CGSize) {
        // Only create loader if URL is valid
        if let validURL = url {
            self.loader = ImageLoader(url: validURL, targetSize: targetSize)
        } else {
            self.loader = nil
        }
    }
    
    var body: some View {
        Group {
            if let image = image {
                #if os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .transition(.opacity)
                #else
                Image(uiImage: image)
                    .resizable()
                #endif
            } else {
                Rectangle()
                    .fill(.secondary)
            }
        }
        .task(id: loader?.url) {
            if let loader = loader {
                image = try? await loader.loadAndGetImage()
            }
        }
    }
}
