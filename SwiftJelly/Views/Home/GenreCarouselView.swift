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
            SectionContainer("Genres") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing) {
                        ForEach(genres.shuffled()) { genre in
                            NavigationLink {
                                GenreRandomItemsView(genreName: genre.name ?? "Genre")
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
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        40
        #else
        10
        #endif
    }
}
