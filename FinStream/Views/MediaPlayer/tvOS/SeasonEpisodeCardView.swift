import SwiftUI
import JellyfinAPI

struct SeasonEpisodeCardView: View {
    let item: BaseItemDto
    let isCurrent: Bool

    var body: some View {
        LandscapeImageView(item: item)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.85)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        if isCurrent {
                            Text("Now Playing")
                                .font(.caption2.weight(.bold))
                                .textCase(.uppercase)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.tint, in: .capsule)
                        }

                        if let label = episodeLabel {
                            Text(label)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.85))
                        }

                        if let name = item.name {
                            Text(name)
                                .font(.footnote)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }
                    }
                    .padding(16)
                }
                .clipShape(.rect(cornerRadius: 16))
            }
    }

    private var episodeLabel: String? {
        item.episodeOnlyString ?? item.seasonEpisodeString
    }
}
