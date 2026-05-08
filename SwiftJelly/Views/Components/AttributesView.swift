//
//  AttributesView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 21/09/2025.
//

import SwiftUI
import JellyfinAPI

struct AttributesView: View {
    let item: BaseItemDto

    var body: some View {
        HStack(spacing: 8) {
            // Year
            if let year = item.productionYear {
                Text(String(year))
            }

            // Runtime (don't show for series)
            if let runTimeTicks = item.runTimeTicks, item.type != .series {
                let totalMinutes = runTimeTicks / 10_000_000 / 60
                let hours = totalMinutes / 60
                let minutes = totalMinutes % 60
                if hours > 0 {
                    dotSeparator
                    Text("\(hours)h \(minutes)m")
                } else {
                    dotSeparator
                    Text("\(minutes)m")
                }
            }

            // Official Rating (PG-13, R, 13+, etc.)
            if let rating = item.officialRating {
                BorderedBadge(text: rating)
            }

            // Resolution
            if let resolution = resolutionLabel {
                BorderedBadge(text: resolution)
            }

            // Audio codec badge (Dolby Atmos, DTS, etc.)
            if let audioBadge = audioBadgeInfo {
                AudioBadgeView(info: audioBadge)
            }

            // SDH
            if hasSDHSubtitles {
                BorderedBadge(text: "SDH")
            }

            // Critic Rating (Rotten Tomatoes)
            if let criticRating = item.criticRating {
                HStack(spacing: 4) {
                    Text(criticRating >= 60 ? "🍅" : "🤢")
                        .font(.caption2)
                    Text("\(Int(criticRating))%")
                }
            }

            // Community Rating (IMDb-style)
            if let communityRating = item.communityRating {
                HStack(spacing: 4) {
                    IMDbBadge()
                    unsafe Text(String(format: "%.1f", communityRating))
                }
            }
        }
        .font(attributeFont)
        .foregroundStyle(.white.opacity(0.9))
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Helpers

    private var dotSeparator: some View {
        Text("•")
            .foregroundStyle(.white.opacity(0.5))
    }

    private var attributeFont: Font {
        #if os(iOS)
        .caption
        #elseif os(tvOS)
        .caption2
        #else
        .subheadline
        #endif
    }

    private var ratingFont: Font {
        #if os(tvOS)
        .body
        #else
        attributeFont
        #endif
    }

    private var resolutionLabel: String? {
        guard let streams = item.mediaSources?.first?.mediaStreams,
              let videoStream = streams.first(where: { $0.type == .video }),
              let width = videoStream.width, let height = videoStream.height else {
            return nil
        }
        if width >= 3840 || height >= 2160 { return "4K" }
        if width >= 1920 || height >= 1080 { return "1080p" }
        if width >= 1280 || height >= 720 { return "720p" }
        if width >= 854 || height >= 480 { return "480p" }
        return nil
    }

    private var audioBadgeInfo: AudioBadgeInfo? {
        guard let streams = item.mediaSources?.first?.mediaStreams else { return nil }
        let audioStreams = streams.filter { $0.type == .audio }

        // Check for Dolby Atmos
        for stream in audioStreams {
            let title = (stream.displayTitle ?? "").lowercased()
            if title.contains("atmos") {
                return .dolbyAtmos
            }
        }

        // Check for Dolby Digital Plus / Dolby Digital
        for stream in audioStreams {
            let codec = (stream.codec ?? "").lowercased()
            if codec == "eac3" { return .dolbyDigitalPlus }
            if codec == "ac3" { return .dolbyDigital }
        }

        // Check for TrueHD
        for stream in audioStreams {
            let codec = (stream.codec ?? "").lowercased()
            if codec == "truehd" { return .dolbyTrueHD }
        }

        // Check for DTS variants
        for stream in audioStreams {
            let codec = (stream.codec ?? "").lowercased()
            let title = (stream.displayTitle ?? "").lowercased()
            if title.contains("dts-hd ma") || title.contains("dts-hd") { return .dtsHDMA }
            if codec == "dts" { return .dts }
        }

        return nil
    }

    private var hasSDHSubtitles: Bool {
        guard let streams = item.mediaSources?.first?.mediaStreams else { return false }
        return streams.filter { $0.type == .subtitle }.contains { stream in
            let title = (stream.displayTitle ?? "").lowercased()
            return title.contains("sdh")
        }
    }
}

// MARK: - Audio Badge Types

enum AudioBadgeInfo {
    case dolbyAtmos
    case dolbyDigitalPlus
    case dolbyDigital
    case dolbyTrueHD
    case dts
    case dtsHDMA

    var label: String {
        switch self {
        case .dolbyAtmos: "ATMOS"
        case .dolbyDigitalPlus: "DD+"
        case .dolbyDigital: "DD"
        case .dolbyTrueHD: "TrueHD"
        case .dts: "DTS"
        case .dtsHDMA: "DTS-HD"
        }
    }

    var isDolby: Bool {
        switch self {
        case .dolbyAtmos, .dolbyDigitalPlus, .dolbyDigital, .dolbyTrueHD: true
        case .dts, .dtsHDMA: false
        }
    }
}

// MARK: - Sub-views

private struct BorderedBadge: View {
    let text: String

    var body: some View {
        Text(text)
            #if os(tvOS)
            .font(.system(size: 16, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(.white.opacity(0.5), lineWidth: 1.5)
            )
            #else
            .font(.system(size: 8, weight: .medium))
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(.white.opacity(0.5), lineWidth: 0.75)
            )
            #endif
    }
}

private struct AudioBadgeView: View {
    let info: AudioBadgeInfo

    var body: some View {
        if info.isDolby {
            HStack(spacing: 2) {
                // Dolby "DD" icon approximation
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 8, weight: .bold))
                Text("Dolby")
                    .fontWeight(.bold)
                    .font(.system(size: 9))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 4))

            if info != .dolbyDigital {
                Text(info.label)
                    .fontWeight(.semibold)
                    .font(.system(size: 9))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        } else {
            Text(info.label)
                .fontWeight(.bold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
}

private struct IMDbBadge: View {
    var body: some View {
        Text("IMDb")
            #if os(tvOS)
            .font(.system(size: 15, weight: .black))
            .foregroundStyle(.black)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.yellow)
            )
            #else
            .font(.system(size: 7.5, weight: .black))
            .foregroundStyle(.black)
            .padding(.horizontal, 3)
            .padding(.vertical, 1.5)
            .background(
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.yellow)
            )
            #endif
    }
}
