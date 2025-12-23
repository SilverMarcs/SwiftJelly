//
//  PlayableCard.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import SwiftUI
import JellyfinAPI

struct PlayableCard: View {
    @Environment(\.refresh) var refresh
    
    let item: BaseItemDto
    var showRealname: Bool = false
    var showDescription: Bool = false
    @State private var showPlayer = false

    #if os(tvOS)
    private let cardWidth: CGFloat = 540
    private let cardHeight: CGFloat = 336
    private let cornerRadius: CGFloat = 30
    private let reflectionHeight: CGFloat = 150
    private let overlayPadding: CGFloat = 30
    #else
    private let cardWidth: CGFloat = 270
    private let cardHeight: CGFloat = 168
    private let cornerRadius: CGFloat = 13
    private let reflectionHeight: CGFloat = 50
    private let overlayPadding: CGFloat = 15
    #endif
    
    let largeGradient = LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .white, location: 0),
                .init(color: .white, location: 0.2),
                .init(color: .white.opacity(0.9), location: 0.4),
                .init(color: .white.opacity(0), location: 0.7),
                .init(color: .white.opacity(0), location: 1.0)
            ]),
            startPoint: .bottom,
            endPoint: .top
        )
    
    let gradient = LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .white, location: 0),
                .init(color: .white.opacity(0.7), location: 0.2),
                .init(color: .white.opacity(0), location: 0.4)
            ]),
            startPoint: .bottom,
            endPoint: .top
        )

    var body: some View {
        PlayMediaButton(item: item) {
            VStack(alignment: .leading) {
                ExpandedImage(image: LandscapeImageView(item: item), imageHeight: cardHeight, reflectionHeight: showDescription ? reflectionHeight : 0)
                    .overlay {
                        Rectangle()
                            .fill(showDescription ? .regularMaterial : .ultraThickMaterial)
                            .mask {
                                if showDescription {
                                    largeGradient
                                } else {
                                    gradient
                                }
                            }
                    }
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text((showRealname ? item.name : (item.seriesName ?? item.name)) ?? "Unknown")
                                .foregroundStyle(.white)
                                .fontWeight(.bold)
                                .opacity(0.7)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .multilineTextAlignment(.leading)

                            if showDescription {
                                Text(item.overview ?? "")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.caption2)
                                    .opacity(0.5)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(3, reservesSpace: false)
                            }
                            
                            ProgressBarOverlay(item: item)
                        }
                        .padding(overlayPadding)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(.gray.opacity(0.5), lineWidth: 1)
                    }
                    .frame(width: cardWidth)
                    .background {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.black)
                    }
                    .environment(\.colorScheme, .dark)
                    
                    #if !os(macOS)
                    .hoverEffect(.highlight)
                    #endif
            }
            .frame(maxWidth: cardWidth)
        }
        .foregroundStyle(.primary)
        .contextMenu {
            if item.type == .movie {
                Section {
                    NavigationLink(value: item) {
                        PlayableItemTypeLabel(item: item)
                    }
                }
            }
            
            if item.type == .episode {
                Section {
                    NavigationLink(value: ShowDetailLoaderNavigationItem(episode: item)) {
                        PlayableItemTypeLabel(item: item)
                    }
                }
            }
            
            Button {
                Task {
                    try? await JFAPI.toggleItemPlayedStatus(item: item)
                    await refresh()
                }
            } label: {
                Label(item.userData?.isPlayed == true ? "Mark as Unwatched" : "Mark as Watched",
                      systemImage: item.userData?.isPlayed == true ? "eye.slash" : "eye")
            }
        }
        .buttonStyle(.borderless)
        .buttonBorderShape(.roundedRectangle(radius: cornerRadius))
    }
}
