//
//  MediaInfoCardsView.swift
//  SwiftJelly
//

import SwiftUI
import JellyfinAPI

struct MediaInfoCardsView: View {
    let item: BaseItemDto

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .center, spacing: spacing) {
                InformationCard(item: item)
                AudioSubtitlesCard(item: item)
                VideoCard(item: item)
            }
            .scenePadding(.horizontal)
        }
        .scrollIndicators(.hidden)
        #if os(tvOS)
        .scrollClipDisabled()
        .padding(40)
        .frame(maxWidth: .infinity)
        .ignoresSafeArea()
        .background(.background.secondary.opacity(0.5))
        .focusSection()
        #endif
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        40
        #else
        12
        #endif
    }
}

// MARK: - Information Card

private struct InformationCard: View {
    let item: BaseItemDto

    var body: some View {
        MediaInfoCard(title: "Information") {
            if let year = item.productionYear {
                MediaInfoRow(label: "Released", value: String(year))
            }
            if let rating = item.officialRating {
                MediaInfoRow(label: "Rated", value: rating)
            }
            if let studio = item.studios?.first?.name {
                MediaInfoRow(label: "Studio", value: studio)
            }
            if let genres = item.genres, !genres.isEmpty {
                MediaInfoRow(label: "Genres", value: genres.joined(separator: ", "))
            }
            if let runTimeTicks = item.runTimeTicks, item.type != .series {
                let minutes = runTimeTicks / 10_000_000 / 60
                MediaInfoRow(label: "Runtime", value: "\(minutes) min")
            }
            if let location = item.productionLocations?.first {
                MediaInfoRow(label: "Region of Origin", value: location)
            }
        }
    }
}

// MARK: - Audio & Subtitles Card

private struct AudioSubtitlesCard: View {
    let item: BaseItemDto

    var body: some View {
        let streams = item.mediaSources?.first?.mediaStreams ?? []
        let audioStreams = streams.filter { $0.type == .audio }
        let subtitleStreams = streams.filter { $0.type == .subtitle }

        if !audioStreams.isEmpty || !subtitleStreams.isEmpty {
            MediaInfoCard(title: "Audio & Subtitles") {
                if !audioStreams.isEmpty {
                    MediaInfoRow(
                        label: "Audio",
                        value: uniqueDisplayTitles(from: audioStreams)
                    )
                }
                if !subtitleStreams.isEmpty {
                    MediaInfoRow(
                        label: "Subtitles",
                        value: uniqueDisplayTitles(from: subtitleStreams)
                    )
                }
            }
        }
    }

    private func uniqueDisplayTitles(from streams: [MediaStream]) -> String {
        var seen = Set<String>()
        return streams
            .compactMap { $0.displayTitle ?? $0.language }
            .filter { seen.insert($0).inserted }
            .joined(separator: ", ")
    }
}

// MARK: - Video Card

private struct VideoCard: View {
    let item: BaseItemDto

    var body: some View {
        let source = item.mediaSources?.first
        let videoStream = (source?.mediaStreams ?? [])
            .first(where: { $0.type == .video })

        if videoStream != nil || source?.container != nil {
            MediaInfoCard(title: "Video") {
                if let stream = videoStream {
                    if let width = stream.width, let height = stream.height {
                        MediaInfoRow(
                            label: "Quality",
                            value: resolutionLabel(width: width, height: height)
                        )
                    }
                    if let codec = stream.codec {
                        MediaInfoRow(label: "Codec", value: codecDisplayName(codec))
                    }
                }
                if let container = source?.container {
                    MediaInfoRow(label: "Container", value: container.uppercased())
                }
                if let bitrate = source?.bitrate {
                    let mbps = Double(bitrate) / 1_000_000
                    MediaInfoRow(
                        label: "Bitrate",
                        value: "\(mbps.formatted(.number.precision(.fractionLength(1)))) Mbps"
                    )
                }
            }
        }
    }

    private func resolutionLabel(width: Int, height: Int) -> String {
        if width >= 3840 || height >= 2160 { return "4K" }
        if width >= 1920 || height >= 1080 { return "1080p" }
        if width >= 1280 || height >= 720 { return "720p" }
        if width >= 854 || height >= 480 { return "480p" }
        return "\(width)×\(height)"
    }

    private func codecDisplayName(_ codec: String) -> String {
        switch codec.lowercased() {
        case "h264", "avc": "H.264"
        case "hevc", "h265": "HEVC"
        case "av1": "AV1"
        case "vp9": "VP9"
        case "mpeg4": "MPEG-4"
        case "mpeg2video": "MPEG-2"
        default: codec.uppercased()
        }
    }
}

// MARK: - Shared Components

/// A card container with a bold title and vertically stacked content rows.
/// On tvOS uses the `.card` button style for the native card appearance.
/// On other platforms adds a material background with a subtle border.
private struct MediaInfoCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        Button {} label: {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                    .bold()

                content
            }
            .padding(30)
            .frame(width: cardWidth, alignment: .topLeading)
            #if !os(tvOS)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
            #endif
        }
        .adaptiveCardButtonStyle()
        .cardBorder()
    }

    private var cardWidth: CGFloat {
        #if os(tvOS)
        450
        #elseif os(iOS)
        280
        #else
        300
        #endif
    }
}

/// A label-value pair displayed vertically within a media info card.
private struct MediaInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption)
        }
    }
}
