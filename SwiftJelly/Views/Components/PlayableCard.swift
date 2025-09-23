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
    var showNavigation: Bool = true
    @State private var showPlayer = false

    var body: some View {
        PlayMediaButton(item: item) {
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
        }
        .buttonStyle(.plain)
        .contextMenu {
            if showNavigation {
                Section {
                    NavigationLink {
                        switch item.type {
                        case .movie:
                            MovieDetailView(item: item)
                        case .episode, .series:
                            ShowDetailView(id: item.seriesID ?? "")
                        default:
                            Text("Unsupported item type")
                        }
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
