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
    
    #if os(tvOS)
    private let itemWidth: CGFloat = 180
    private let spacing: CGFloat = 40
    #else
    private let itemWidth: CGFloat = 120
    private let spacing: CGFloat = 12
    #endif
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !similarItems.isEmpty {
                Text("Recommended")
                    #if os(tvOS)
                    .font(.title3)
                    .fontWeight(.bold)
                    #else
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                    .padding(.top)
                    #endif
            
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing) {
                        ListStartItemSpacer()

                        ForEach(similarItems) { item in
                            MediaNavigationLink(item: item)
                                .frame(width: itemWidth)
                        }
                    }
                }
                #if os(tvOS)
                .scrollClipDisabled()
                #endif
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
            print("Error loading Similar Items: \(error.localizedDescription)")
        }
    }
}
