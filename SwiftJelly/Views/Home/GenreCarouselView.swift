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
    @State private var isLoading = false

    var body: some View {
        SectionContainer(showHeader: !genres.isEmpty || isLoading) {
            if !genres.isEmpty {
                HorizontalShelf(spacing: spacing) {
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

            if isLoading {
                UniversalProgressView()
                    .frame(maxWidth: .infinity)
                    .scenePadding(.horizontal)
            }
        } header: {
            Text("Genres")
        }
        .task {
            await loadGenres()
        }
    }
    
    private func loadGenres() async {
        if !genres.isEmpty { return }
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let genres = try await JFAPI.loadGenres(limit: 20)
            withAnimation { self.genres = genres }
        } catch {
            print("Error loading genres: \(error)")
        }
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        30
        #else
        10
        #endif
    }
}
