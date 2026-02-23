//
//  GenreCarouselView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 13/12/2025.
//

import SwiftUI
import JellyfinAPI

struct GenreCarouselView: View {
    @State private var genres: [ViewListItem<BaseItemDto>] = withPlaceholderItems(size: 10)
    @State private var isLoaded = false

    var body: some View {
        SectionContainer {
            HorizontalShelf(spacing: spacing) {
                ForEach(genres.shuffled()) { genre in
                    NavigationLink(value: genre.base) {
                        GenreCardView(name: genre.base?.name ?? " ")
                    }
                    .id("\(genre.id)-\(genre.base?.name ?? "")")
                    .adaptiveCardButtonStyle()
                }
            }
        } header: {
            Text("Genres")
        }
        .task {
            await loadGenres()
        }
    }
    
    private func loadGenres() async {
        if isLoaded { return }
        
        do {
            let genres = try await JFAPI.loadGenres(limit: 20)
            isLoaded = true
            
            await MainActor.run {
                self.genres.update(with: genres)
            }
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


#Preview {
    GenreCarouselView()
}
