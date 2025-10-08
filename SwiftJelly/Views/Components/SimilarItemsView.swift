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
        VStack(alignment: .leading) {
            if !similarItems.isEmpty {
                Text("Recommended")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
            
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(similarItems) { item in
                            MediaNavigationLink(item: item)
                                .frame(width: 120)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .overlay {
            if isLoading {
                ProgressView()
                    .padding()
            }
        }
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
            print(error.localizedDescription)
        }
    }
}
