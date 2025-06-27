//
//  AsyncImageView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI

struct AsyncImageView: View {
    let url: URL?
    let aspectRatio: CGFloat
    let contentMode: ContentMode
    
    init(url: URL?, aspectRatio: CGFloat = 1.0, contentMode: ContentMode = .fill) {
        self.url = url
        self.aspectRatio = aspectRatio
        self.contentMode = contentMode
    }
    
    var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(aspectRatio, contentMode: contentMode)
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(aspectRatio, contentMode: .fit)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                        .font(.largeTitle)
                }
        }
    }
}

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                placeholder()
            case .success(let image):
                content(image)
            case .failure(_):
                placeholder()
            @unknown default:
                placeholder()
            }
        }
    }
}
