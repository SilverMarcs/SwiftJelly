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
    
    var body: some View {
        MediaShelf(header: "Similar") {
            try await JFAPI.loadSimilarItems(for: item)
        }
    }
}
