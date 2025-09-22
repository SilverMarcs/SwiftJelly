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
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(items, id: \.id) { item in
                        PlayableCard(item: item)
                    }
                }
            }
        }
    }
}
