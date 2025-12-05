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

    #if os(tvOS)
    private let spacing: CGFloat = 40
    #else
    private let spacing: CGFloat = 12
    #endif

    var body: some View {
        if !items.isEmpty {
            #if os(tvOS)
            VStack(alignment: .leading, spacing: 16) {
                Text("Continue Watching")
                    .font(.title3)
                    .fontWeight(.bold)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing) {
                        ForEach(items, id: \.id) { item in
                            PlayableCard(item: item, showTitle: false)
                        }
                    }
                }
                .scrollClipDisabled()
            }
            #else
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    ForEach(items, id: \.id) { item in
                        PlayableCard(item: item)
                    }
                }
            }
            #endif
        }
    }
}
