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
        SectionContainer("Genres", showHeader: !genres.isEmpty) {
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
//        destination: {
//            ScrollView {
//                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
//                    ForEach(genres) { genre in
//                        NavigationLink {
//                            FilteredMediaView(filter: .genre(genre.name ?? "Genre"))
//                        } label: {
//                            GenreCardView(name: genre.name ?? "Genre")
//                        }
//                        .adaptiveButtonStyle()
//                    }
//                }
//                .scenePadding()
//            }
//            .navigationTitle("Genres")
//            .toolbarTitleDisplayMode(.inline)
//        }
        .task {
            if genres.isEmpty {
                await loadGenres()
            }
        }
    }
    
    private func loadGenres() async {
        do {
            let genres = try await JFAPI.loadGenres(limit: 20)
            withAnimation {
                self.genres = genres
            }
        } catch {
            print("Error loading genres: \(error)")
        }
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        40
        #else
        7
        #endif
    }

    private var cardWidth: CGFloat {
        #if os(tvOS)
        250
        #elseif os(iOS)
        125
        #else
        150
        #endif
    }
}
