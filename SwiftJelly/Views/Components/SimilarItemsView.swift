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
                Text("Recommended")
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.top)
                    .scenePadding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing) {
                        ForEach(similarItems) { item in
                            MediaNavigationLink(item: item)
                                .frame(width: itemWidth)
                        }
                    }
                    .scenePadding(.horizontal)
                }
                #if os(tvOS)
                .scrollClipDisabled()
                #endif
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
    
    private var itemWidth: CGFloat {
        #if os(tvOS)
        180
        #else
        120
        #endif
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        40
        #else
        12
        #endif
    }
}
