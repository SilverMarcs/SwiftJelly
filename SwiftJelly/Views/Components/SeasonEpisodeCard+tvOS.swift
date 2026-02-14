//
//  SeasonEpisodeCard+tvOS.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 06.02.26.
//
//  Custom SeasonEpisodeCard for tvOS. It has a different layout for improved accessibility with a remote.
//  Clicking on the episode card will play the episode.
//  The item description has its own button, so it is easily selectable with a remote to open details for that episode.
//  This component observes focus states and manipulates a few things manually to achieve the correct visual effetcs, for example:
//    - the description card should only be accessable when the parent episode card is selected
//    - scrolling left or right on the remote when the description card is selected should result in focusing the neighbour episode card instead of the description card
//    - when the episode card is focused, the description card should adjust its y-offset to allow for a spacing between the episode card and the description
//  Most of this behaviour is simply achieved by toggling `.disabled` of the description card based on `!episodeCardFocused && !descriptionFocused`
//

#if os(tvOS)

import SwiftUI
import JellyfinAPI

struct SeasonEpisodeCard: View {
    @Environment(\.refresh) var refresh
    let item: ViewListItem<BaseItemDto>
    @FocusState private var episodeCardFocused: Bool
    @FocusState private var descriptionFocused: Bool

    private let cardWidth: CGFloat = 450
    private var cardHeight: CGFloat { cardWidth * 0.5625 }
    
    var body: some View {
        let episodeCardFocused = episodeCardFocused
        let descriptionFocused = descriptionFocused
        
        VStack(spacing: 5) {
            PlayMediaButton(item: item.base) {
                LandscapeImageView(item: item.base) {
                    Image(systemName: "ellipsis")
                        .font(.title)
                        .frame(width: cardWidth, height: cardHeight, alignment: .center)
                        .opacity(0.3)
                }
                .scaledToFill()
                .frame(width: cardWidth, height: cardHeight, alignment: .top)
                .background(Color("Card Background"))
                .clipped()
                .overlay(alignment: .bottom) {
                    if item.base != nil {
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .black.opacity(1.0), location: 0),
                                .init(color: .black.opacity(0.5), location: 0.6),
                                .init(color: .clear, location: 1.0)
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .frame(height: 50)
                    }
                }
                .overlay(alignment: .bottom) {
                    if let episodeItem = item.base {
                        ProgressBarOverlay(item: episodeItem, showEpisodeInformation: false)
                            .padding(.vertical, 15)
                            .padding(.horizontal, 20)
                    }
                }
            }
            .focused($episodeCardFocused)
            .buttonStyle(.card)
            .buttonBorderShape(.roundedRectangle(radius: 28))
            .contextMenu {
                if let episodeItem = item.base {
                    Button {
                        Task {
                            try? await JFAPI.toggleItemPlayedStatus(item: episodeItem)
                            await refresh()
                        }
                    } label: {
                        Label(
                            episodeItem.userData?.isPlayed == true ? "Mark as Unwatched" : "Mark as Watched",
                            systemImage: episodeItem.userData?.isPlayed == true ? "eye.slash" : "eye"
                        )
                    }
                }
            }

            .visualEffect { content, geometry in
                content.offset(y: descriptionFocused ? -25 : 0)
            }
            .animation(.snappy, value: descriptionFocused)
            
            Button(action: {}) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(item.base?.longEpisodeOnlyString?.uppercased() ?? "")
                        .foregroundStyle(.white)
                        .font(.caption2.scaled(by: 0.7))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .multilineTextAlignment(.leading)
                    
                    Text(item.base?.name ?? "")
                        .foregroundStyle(.white)
                        .font(.caption)
                        .bold()
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .multilineTextAlignment(.leading)
                        .padding(.bottom, 5)
                    
                    Text(item.base?.overview ?? "")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.caption2)
                        .opacity(0.7)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3, reservesSpace: true)
                }
                .padding(24)
                .frame(height: 170)
            }
            .focused($descriptionFocused)
            .frame(maxWidth: cardWidth)
            .visualEffect { content, geometry in
                content
                    .offset(y: episodeCardFocused ? 25 : 0)
                    .opacity(episodeCardFocused || descriptionFocused ? 1.0 : 0.6)
//                    .scaleEffect(episodeCardFocused || descriptionFocused ? 1.06 : 1.0)
            }
            .animation(.snappy, value: episodeCardFocused)
            .animation(.snappy, value: descriptionFocused)
            .buttonStyle(.card)
            .disabled(!episodeCardFocused && !descriptionFocused || item.base == nil)
            .buttonBorderShape(.roundedRectangle(radius: 25))
        }
        .focusSection()
    }
}

#Preview {
    SeasonEpisodeCard(item: ViewListItem(id: "test", base: BaseItemDto(indexNumber: 12, parentIndexNumber: 5, runTimeTicks: 30000, userData: UserItemDataDto(playbackPositionTicks: 1300, isPlayed: true))))
}

#endif

