//
//  GenreCarouselView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 13/12/2025.
//

import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct GenreCarouselView: View {
    let genres: [BaseItemDto]

    var body: some View {
        SectionContainer("Genres") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    ForEach(genres.shuffled()) { genre in
                        NavigationLink {
                            GenreRandomMoviesView(genreName: genre.name ?? "Genre")
                        } label: {
                            GenreCardView(name: genre.name ?? "Genre")
                        }
                        .adaptiveButtonStyle()
                    }
                }
                #if !os(tvOS)
                .scenePadding(.horizontal)
                #endif
            }
        }
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        40
        #elseif os(macOS)
        15
        #else
        12
        #endif
    }
}

private struct GenreCardView: View {
    let name: String

    var body: some View {
        CachedAsyncImage(url: ImageURLProvider.genreImageURL(forGenreName: name), targetSize: 500)
            .aspectRatio(250/375, contentMode: .fill)
            .overlay {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.65)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .bottomLeading) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
            }
            .frame(width: itemWidth)
            .cardBorder()
    }
    
    private var itemWidth: CGFloat {
        #if os(tvOS)
        250
        #elseif os(iOS)
        125
        #else
        150
        #endif
    }
}
