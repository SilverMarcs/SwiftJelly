//
//  HorizontalMediaScrollView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import SwiftUI
import JellyfinAPI

struct SimilarItemsView: View {
    let item: BaseItemDto
    @State private var isLoading: Bool = false
    @State private var similarItems: [BaseItemDto] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isLoading {
                ProgressView()
                    .controlSize(.extraLarge)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            }
            
            if !similarItems.isEmpty {
                MediaShelf(items: similarItems, header: "Recommended")
            }
        }
        .padding(.top)
        .task {
            if similarItems.isEmpty {
                await fetchSimilarItems()
            }
        }
    }
    
    private func fetchSimilarItems() async {
        isLoading = true
        defer { isLoading = false }
        do {
            similarItems = try await JFAPI.loadSimilarItems(for: item)
        } catch {
            print("Error loading Similar Items: \(error.localizedDescription)")
        }
    }
}
