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
            .refreshable {
                await fetchFavorites()
            }
            .overlay {
                if isLoading {
                    UniversalProgressView()
                }
            }
            .navigationTitle("Favorites")
            #if os(tvOS)
            .toolbar(.hidden, for: .navigationBar)
            #elseif os(macOS)
            .toolbar {
                Button {
                    Task { await fetchFavorites() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r")
            }
            #else
            .toolbarTitleDisplayMode(.inlineLarge)
            #endif
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
