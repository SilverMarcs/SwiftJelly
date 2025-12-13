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
    
    var body: some View {
        PlayMediaButton(item: item) {
            LabelStack(alignment: .leading) {
                LandscapeImageView(item: item)
                    .frame(width: cardWidth, height: cardHeight)
                    .overlay(alignment: .bottom) {
                        LinearGradient(
                            colors: [.black.opacity(0.8), .black.opacity(0.5), .black.opacity(0.2), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .frame(height: 70)
                    }
                    .overlay(alignment: .bottom) {
                        ProgressBarOverlay(item: item)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 8)
                    }
                    .clipShape(.rect(cornerRadius: cornerRadius))
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
                        .frame(maxWidth: cardWidth, alignment: .leading)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 4)
                }
                
                if showDescription {
                    Text(item.overview ?? "")
                        .frame(maxWidth: cardWidth, alignment: .leading)
                        .font(.caption2)
                        .opacity(0.7)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3, reservesSpace: true)
                        .padding(.horizontal, 4)
                }
            }
        }
        .foregroundStyle(.primary)
        #if os(tvOS)
        .buttonStyle(.borderless)
        #else
        .buttonStyle(.plain)
        #endif
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

    }

    private var cardWidth: CGFloat {
        #if os(tvOS)
        456
        #else
        270
        #endif
    }
    
    private var cardHeight: CGFloat {
        #if os(tvOS)
        257
        #else
        168
        #endif
    }
    
    private var cornerRadius: CGFloat {
        #if os(tvOS)
        12
        #else
        10
        #endif
    }
}
