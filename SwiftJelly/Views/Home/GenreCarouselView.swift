//
//  GenreCarouselView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 13/12/2025.
//

import SwiftUI
import JellyfinAPI

struct GenreCarouselView: View {
    @State private var genres: [BaseItemDto] = []

    var body: some View {
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
        .task {
            if genres.isEmpty {
                await loadGenres()
            }
        }
    }
    
    private func loadGenres() async {
        do {
            genres = try await JFAPI.loadGenres(limit: 20)
        } catch {
            print("Error loading genres: \(error)")
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
