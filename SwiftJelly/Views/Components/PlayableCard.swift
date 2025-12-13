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
    @Environment(\.isInSeasonView) private var isInSeasonView
    
    let item: BaseItemDto
    var showRealname: Bool = false
    var showTitle: Bool = true
    var showDescription: Bool = false
    
    @State private var showPlayer = false
    
    var body: some View {
        PlayMediaButton(item: item) {
            LabelStack(alignment: .leading) {
                LandscapeImageView(item: item)
                    .aspectRatio(16/9, contentMode: .fit)
                    .frame(width: cardWidth)
                    .blurredBottomOverlay()
                    .overlay(alignment: .bottom) {
                        ProgressBarOverlay(item: item)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 8)
                        #if os(tvOS)
                            .padding(7)
                        #endif
                    }
                    .cardBorder()
                    #if os(tvOS)
                    .hoverEffect(.highlight)
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
        .adaptiveButtonStyle()
        .contextMenu {
            if !isInSeasonView {
                Section {
                    MediaNavigationLink(item: item) {
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
        548
        #else
        280
        #endif
    }
}
