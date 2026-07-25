//
//  UserAvatarView.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 25.07.26.
//

import SwiftUI
import SwiftMediaViewer

/// Circular avatar for a server's authenticated user, falling back to a person
/// icon when no profile image is available.
struct UserAvatarView: View {
    let server: Server
    var size: CGFloat = 32

    var body: some View {
        Group {
            if let url = ImageURLProvider.userImageURL(for: server) {
                CachedAsyncImage(url: url, targetSize: Int(size * 3)) {
                    placeholder
                }
                .aspectRatio(contentMode: .fill)
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .background(.background.secondary)
        .clipShape(.circle)
        .overlay {
            Circle().strokeBorder(.tertiary, lineWidth: 0.5)
        }
    }

    private var placeholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.secondary)
    }
}
