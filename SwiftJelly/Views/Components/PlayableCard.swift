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
    @State private var showPlayer = false

    var body: some View {
        PlayMediaButton(item: item) {
            VStack(alignment: .leading) {
                LandscapeImageView(item: item)
                    .frame(width: 270, height: 168)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(alignment: .bottom) {
                        ZStack(alignment: .bottom) {
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black.opacity(0.9), Color.clear]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            .frame(height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            
                            ProgressBarOverlay(item: item)
                                .padding(.horizontal, 10)
                                .padding(.bottom, 8)
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
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
}
