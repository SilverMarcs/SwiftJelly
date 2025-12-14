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
            SectionContainer("Continue Watching", showHeader: isTVOS, spacing: spacing) {
                ForEach(items, id: \.id) { item in
                    PlayableCard(item: item)
                }
            }
        }
    }
    
    private var isTVOS: Bool {
        #if os(tvOS)
        true
        #else
        false
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
