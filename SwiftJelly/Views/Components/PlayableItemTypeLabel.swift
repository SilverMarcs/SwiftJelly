//
//  PlayableItemTypeLabel.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import JellyfinAPI

struct PlayableItemTypeLabel: View {
    let item: BaseItemDto
    
    var body: some View {
        switch item.type {
        case .movie:
            Label("Go to Movie", systemImage: "film")
        case .episode:
            Label("Go to Episode", systemImage: "tv")
        case .series:
            Label("Go to Show", systemImage: "play.tv")
        default:
            Label(item.type?.rawValue.capitalized ?? "Unknown", systemImage: "questionmark.circle")
        }
    }
}
