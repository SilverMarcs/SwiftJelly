//
//  DiscoverCard.swift
//  SwiftJelly
//

import SwiftUI
import SwiftMediaViewer

struct DiscoverCard: View {
    let item: SeerrSearchResult
    let isMatching: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            LabelStack(alignment: .leading) {
                Group {
                    if let url = item.posterURL {
                        CachedAsyncImage(url: url, targetSize: 500) {
                            placeholder
                        }
                    } else {
                        placeholder
                    }
                }
                .aspectRatio(1/1.5, contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.background.secondary)
                .cardBorder()
                .clipped()
                .overlay {
                    if isMatching {
                        ZStack {
                            Color.black.opacity(0.3)
                            ProgressView()
                        }
                    }
                }
            }
        }
        .adaptiveCardButtonStyle()
        .disabled(isMatching)
    }

    private var placeholder: some View {
        Image(systemName: "film")
            .font(.title)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
