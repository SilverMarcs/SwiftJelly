//
//  ContinueWatchingView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import JellyfinAPI

struct ContinueWatchingView: View {
    let items: [BaseItemDto]

    var body: some View {
        if !items.isEmpty {
            #if os(tvOS)
            VStack(alignment: .leading, spacing: 16) {
                Text("Continue Watching")
                    .font(.title3.bold())
                    .scenePadding(.horizontal)
                
                carousell
                    .scrollClipDisabled()
            }
            #else
            carousell
            #endif
        }
    }
    
    var carousell: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                ForEach(items, id: \.id) { item in
                    PlayableCard(item: item, showTitle: false)
                }
            }
            .scenePadding(.horizontal)
        }
    }
    
    private var spacing: CGFloat {
        #if os(tvOS)
        40
        #else
        12
        #endif
    }
}
