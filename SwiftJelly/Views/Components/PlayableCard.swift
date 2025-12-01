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
    @State private var showPlayer = false

    #if os(tvOS)
    private let cardWidth: CGFloat = 380
    private let cardHeight: CGFloat = 214
    private let cornerRadius: CGFloat = 12
    #else
    private let cardWidth: CGFloat = 270
    private let cardHeight: CGFloat = 168
    private let cornerRadius: CGFloat = 10
    #endif

    var body: some View {
        #if os(tvOS)
        tvOSCard
        #else
        standardCard
        #endif
    }
    
    #if os(tvOS)
    private var tvOSCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            PlayMediaButton(item: item) {
                LandscapeImageView(item: item)
                    .frame(width: cardWidth, height: cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .overlay(alignment: .bottomLeading) {
                        HStack(spacing: 6) {
                            if let progress = item.playbackProgress, progress > 0, progress < 1 {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.caption2)
                            } else {
                                Image(systemName: "play.fill")
                                    .font(.caption2)
                            }
                            
                            Text(item.totalDurationString ?? "")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                        .padding(10)
                    }
            }
            .buttonStyle(.card)
            
            if showTitle {
                Text(item.name ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .frame(width: cardWidth, alignment: .leading)
            }
        }
    }
    #endif
    
    private var standardCard: some View {
        PlayMediaButton(item: item) {
            VStack(alignment: .leading) {
                LandscapeImageView(item: item)
                    .frame(width: cardWidth, height: cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .overlay(alignment: .bottom) {
                        ZStack(alignment: .bottom) {
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black.opacity(0.9), Color.clear]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            .frame(height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                            
                            ProgressBarOverlay(item: item)
                                .padding(.horizontal, 10)
                                .padding(.bottom, 8)
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(.background.quinary, lineWidth: 1)
                    }
                
                Text((showRealname ? item.name : (item.seriesName ?? item.name)) ?? "Unknown")
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 4)
            }
        }
        .buttonStyle(.plain)
        #if !os(tvOS)
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
        #endif
    }
}
