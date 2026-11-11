//
//  SeasonEpisodeCard+tvOS.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 06.02.26.
//
//  The description card is only focusable while its episode card is focused, so left/right moves between
//  episode cards. Achieved by toggling `.disabled` on `!episodeCardFocused && !descriptionFocused`.
//

import SwiftUI
import JellyfinAPI

struct SeasonEpisodeCard: View {
    @Environment(\.refresh) var refresh
    let item: ViewListItem<BaseItemDto>
    var focusedEpisodeID: FocusState<String?>.Binding? = nil
    @FocusState private var localEpisodeID: String?

    private var episodeCardFocused: Bool {
        (focusedEpisodeID?.wrappedValue ?? localEpisodeID) == item.id
    }
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
                        .foregroundStyle(.secondary)
                }
                .scaledToFill()
                .frame(width: cardWidth, height: cardHeight, alignment: .top)
                .background(.background.secondary)
                .clipped()
                .overlay(alignment: .bottom) {
                    if let episodeItem = item.base {
                        ProgressBarOverlay(item: episodeItem, showEpisodeInformation: false)
                            .padding(.vertical, 15)
                            .padding(.horizontal, 20)
                    }
                }
            }
            .focused(focusedEpisodeID ?? $localEpisodeID, equals: item.id)
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

            descriptionButton
                .buttonStyle(DescriptionCardButtonStyle(isActive: episodeCardFocused || descriptionFocused))
                .visualEffect { content, geometry in
                    content
                        .offset(y: episodeCardFocused ? 25 : 0)
                        .opacity(episodeCardFocused || descriptionFocused ? 1.0 : 0.6)
                }
                .animation(.snappy, value: episodeCardFocused)
                .animation(.snappy, value: descriptionFocused)
                .disabled(item.base == nil || (!episodeCardFocused && !descriptionFocused))
                .buttonBorderShape(.roundedRectangle(radius: 25))
        }
        .focusSection()
    }

    private var descriptionButton: some View {
        NavigationLink(value: item.base.map { NavigationRoute.media($0) }) {
            let isPlaceholder = item.base == nil
            VStack(alignment: .leading, spacing: 0) {
                Text(item.base?.longEpisodeOnlyString?.uppercased() ?? "SEASON 1 EPISODE 1")
                    .foregroundStyle(.white)
                    .font(.caption2.scaled(by: 0.7))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .multilineTextAlignment(.leading)
                    .redacted(reason: isPlaceholder ? .placeholder : [])

                Text(item.base?.name ?? "Loading Episode Title")
                    .foregroundStyle(.white)
                    .font(.caption)
                    .bold()
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 5)
                    .redacted(reason: isPlaceholder ? .placeholder : [])

                Text(item.base?.overview ?? "A placeholder description that occupies enough room to mimic the real episode overview while content is loading.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.caption2)
                    .opacity(0.7)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3, reservesSpace: true)
                    .redacted(reason: isPlaceholder ? .placeholder : [])
            }
            .padding(24)
            .frame(height: 170)
        }
        .focused($descriptionFocused)
        .frame(maxWidth: cardWidth + 30)
    }
}

/// `.card` always draws its platter; this one stays transparent while inactive.
private struct DescriptionCardButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: 25)
                    .fill(.quaternary)
                    .opacity(isActive ? 1 : 0)
            }
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .hoverEffect(.highlight)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy, value: isActive)
            .animation(.snappy, value: configuration.isPressed)
    }
}

#Preview {
    SeasonEpisodeCard(item: ViewListItem(id: "test", base: BaseItemDto(indexNumber: 12, parentIndexNumber: 5, runTimeTicks: 30000, userData: UserItemDataDto(playbackPositionTicks: 1300, isPlayed: true))))
}
