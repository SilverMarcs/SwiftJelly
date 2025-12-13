//
//  FavoritesView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 24/09/2025.
//

import SwiftUI
import JellyfinAPI

struct FavoritesView: View {
    @State var isLoading: Bool = false
    @State var favorites: [BaseItemDto] = []
    
    var body: some View {
        MediaGrid(items: favorites, isLoading: isLoading)
            .task {
                if favorites.isEmpty {
                    isLoading = true
                    await fetchFavorites()
                    isLoading = false
                }
            }
            .overlay {
                if isLoading && favorites.isEmpty {
                    UniversalProgressView()
                }
            }
            .navigationTitle("Favorites")
            .refreshToolbar {
                await fetchFavorites()
            }
            .platformNavigationToolbar()
    }
    
    func fetchFavorites() async {
        do {
            favorites = try await JFAPI.loadFavoriteItems(limit: 15)
        } catch {
            print("Error loading Favorites: \(error.localizedDescription)")
        }
    }
}

#Preview {
    FavoritesView()
}
