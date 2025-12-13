//
//  GenreCarouselView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 13/12/2025.
//

import SwiftUI
import JellyfinAPI

struct GenreCarouselView: View {
    let genres: [BaseItemDto]

    var body: some View {
        if !genres.isEmpty {
            SectionContainer("Genres", spacing: spacing) {
                ForEach(genres.shuffled()) { genre in
                    NavigationLink {
                        FilteredMediaView(filter: .genre(genre.name ?? "Genre"))
                    } label: {
                        GenreCardView(name: genre.name ?? "Genre")
                    }
                    .adaptiveButtonStyle()
                }
            }
        }
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        35
        #else
        10
        #endif
    }
}
