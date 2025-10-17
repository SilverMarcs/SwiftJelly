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
        NavigationStack {
            MediaGrid(items: favorites, isLoading: isLoading)
                .task {
                    if favorites.isEmpty {
                        await fetchFavorites()
                    }
                }
                .overlay {
                    if isLoading {
                        UniversalProgressView()
                    }
                }
                .navigationTitle("Favorites")
                .toolbarTitleDisplayMode(.inlineLarge)
                .refreshable {
                    await fetchFavorites()
                }
                .toolbar {
                    #if os(macOS)
                    Button {
                        Task { await fetchFavorites() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .keyboardShortcut("r")
                    #else
                    SettingsToolbar()
                    #endif
                }
        }
    }
    
    func fetchFavorites() async {
        isLoading = true
        defer { isLoading = false }
        
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
