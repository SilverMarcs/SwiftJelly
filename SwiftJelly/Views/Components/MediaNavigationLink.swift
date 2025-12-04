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
    @Namespace private var animation
    
    @ViewBuilder
    private var destination: some View {
        switch item.type {
        case .movie:
            MovieDetailView(item: item)
#if !os(macOS)
                .navigationTransition(.zoom(sourceID: item.id, in: animation))
#endif
        case .series:
            ShowDetailView(item: item)
#if !os(macOS)
                .navigationTransition(.zoom(sourceID: item.id, in: animation))
#endif
        case .boxSet:
            FilteredMediaView(filter: .library(item))
#if !os(macOS)
                .navigationTransition(.zoom(sourceID: item.id, in: animation))
#endif
        default:
            Text("Unsupported item type")
        }
    }
    
    var body: some View {
        #if os(tvOS)
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
        #else
        NavigationLink(destination: destination) {
            MediaCard(item: item)
        }
        .matchedTransitionSource(id: item.id, in: animation)
        .buttonStyle(.plain)
        #endif
    }
}
