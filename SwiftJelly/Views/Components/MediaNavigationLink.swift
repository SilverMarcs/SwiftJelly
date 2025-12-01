//
//  MediaNavigationLink.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import JellyfinAPI

struct MediaNavigationLink: View {
    let item: BaseItemDto
    
    @ViewBuilder
    private var destination: some View {
        switch item.type {
        case .movie:
            MovieDetailView(item: item)
        case .series:
            ShowDetailView(item: item)
        case .boxSet:
            FilteredMediaView(filter: .library(item))
        default:
            Text("Unsupported item type")
        }
    }
    
    var body: some View {
        #if os(tvOS)
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink(destination: destination) {
                PortraitImageView(item: item)
                    .aspectRatio(2/3, contentMode: .fill)
                    .overlay(alignment: .topTrailing) {
                        if item.userData?.isPlayed ?? false {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white, .green)
                                .shadow(radius: 4)
                                .padding(12)
                        }
                    }
                    .overlay(alignment: .bottomLeading) {
                        if item.userData?.isFavorite == true {
                            Image(systemName: "star.fill")
                                .font(.subheadline)
                                .foregroundStyle(.yellow)
                                .shadow(radius: 4)
                                .padding(12)
                        }
                    }
            }
            .buttonStyle(.card)
        }
        #else
        NavigationLink(destination: destination) {
            MediaCard(item: item)
        }
        .buttonStyle(.plain)
        #endif
    }
}
