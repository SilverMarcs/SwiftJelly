//
//  PersonMediaView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 21/09/2025.
//

import SwiftUI
import JellyfinAPI

struct PersonMediaView: View {
    let person: BaseItemPerson
    @State private var items: [BaseItemDto] = []
    @State private var isLoading = false
    
    var body: some View {
        MediaGrid(items: items, isLoading: isLoading)
            .navigationTitle(person.name ?? "Person")
            .toolbarTitleDisplayMode(.inline)
            .task {
                if items.isEmpty {
                    isLoading = true
                    await loadItems()
                    isLoading = false
                }
            }
            #if !os(tvOS)
            .refreshable {
                await loadItems()
            }
            #endif
    }

    private func loadItems() async {
        do {
            items = try await JFAPI.loadPersonMedia(for: person)
        } catch {
            print("Error loading person media: \(error.localizedDescription)")
        }
    }
}
