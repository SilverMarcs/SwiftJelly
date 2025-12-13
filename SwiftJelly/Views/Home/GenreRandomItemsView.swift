//
//  GenreRandomMoviesView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 13/12/2025.
//

import SwiftUI
import JellyfinAPI

struct GenreRandomItemsView: View {
    let genreName: String

    @State private var items: [BaseItemDto] = []
    @State private var isLoading = false

    var body: some View {
        MediaGrid(items: items, isLoading: isLoading)
            .navigationTitle(genreName)
            .toolbarTitleDisplayMode(.inline)
            .task {
                if items.isEmpty {
                    await load()
                }
            }
            .refreshable {
                await load()
            }
            .refreshToolbar {
                await load()
            }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await JFAPI.loadRandomItems(genreName, limit: 40)
        } catch {
            items = []
            print("Error loading random movies for genre \(genreName): \(error.localizedDescription)")
        }
    }
}
