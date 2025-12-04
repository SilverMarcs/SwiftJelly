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
    var showTitle: Bool = true
    var showDescription: Bool = false
    @State private var showPlayer = false

    #if os(tvOS)
    private let cardWidth: CGFloat = 456
    private let cardHeight: CGFloat = 257
    private let cornerRadius: CGFloat = 12
    #else
    private let cardWidth: CGFloat = 270
    private let cardHeight: CGFloat = 168
    private let cornerRadius: CGFloat = 10
    #endif
    
    let gradient = LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .white, location: 0),
                .init(color: .white, location: 0.6),
                .init(color: .white.opacity(0.1), location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

    var body: some View {
        standardCard
    }
    
    private var standardCard: some View {
        VStack {
            PlayMediaButton(item: item) {
                VStack(alignment: .leading) {
                    LandscapeImageView(item: item)
                        .mask {
                            Rectangle()
                                .fill(.regularMaterial)
                                .mask {
                                    gradient
                                }
                        }
                        .frame(width: cardWidth, height: cardHeight)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        .overlay(alignment: .bottom) {
                            ProgressBarOverlay(item: item)
                                .padding(.horizontal, 10)
                                .padding(.bottom, 8)
                        }
                        .background {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(.black)
                        }

                        #if !os(macOS)
                        .hoverEffect(.highlight)
                        #endif
                        
                        #if !os(tvOS)
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .strokeBorder(.background.quinary, lineWidth: 1)
                        }
                        #endif

                    if showTitle {
                        Text((showRealname ? item.name : (item.seriesName ?? item.name)) ?? "Unknown")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 4)
                    }
                }
                .frame(maxWidth: cardWidth)
            }
            .foregroundStyle(.primary)
            .buttonStyle(.borderless)
            .contextMenu {
                if item.type == .movie {
                    Section {
                        NavigationLink {
                            MovieDetailView(item: item)
                        } label: {
                            PlayableItemTypeLabel(item: item)
                        }
                    }
                }
                
                if item.type == .episode {
                    Section {
                        NavigationLink {
                            ShowDetailLoader(episode: item)
                        } label: {
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

            if showDescription {
                Text(item.overview ?? "")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.caption2)
                    .opacity(0.7)
                    .multilineTextAlignment(.leading)
                    .lineLimit(5, reservesSpace: true)
                    .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: cardWidth)
    }
}
