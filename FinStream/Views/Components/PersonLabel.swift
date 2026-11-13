//
//  PersonLabel.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI
import SwiftMediaViewer

struct PersonLabel: View {
    static var imageSize: CGFloat {
        #if os(tvOS)
        200
        #else
        100
        #endif
    }

    let imageURL: URL?
    let name: String
    let subtitle: String?

    var body: some View {
        LabelStack {
            CachedAsyncImage(url: imageURL, targetSize: Int(Self.imageSize * 2)) {
                Image(systemName: "person.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
            .aspectRatio(contentMode: .fill)
            .frame(width: Self.imageSize, height: Self.imageSize)
            .background(.background.secondary)
            .overlay {
                Circle()
                    .strokeBorder(.tertiary, lineWidth: 0.5)
            }
            #if !os(macOS)
            .hoverEffect(.highlight)
            #endif
            #if !os(tvOS)
            .clipShape(.circle)
            .clipped()
            #endif

            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }
}
