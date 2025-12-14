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
        SectionContainer("Continue Watching", showHeader: !items.isEmpty, spacing: spacing) {
            ForEach(items, id: \.id) { item in
                PlayableCard(item: item)
            }
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
