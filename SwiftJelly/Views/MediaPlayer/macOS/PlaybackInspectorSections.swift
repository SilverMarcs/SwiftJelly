//
//  PlaybackInspectorSections.swift
//  SwiftJelly
//

import SwiftUI
import JellyfinAPI

struct PlaybackInspectorSections: View {
    let info: PlaybackInfoResponse
    @AppStorage("maxStreamingBitrate") private var requestedQuality: MaxBitratePreference = .p1080

    var body: some View {
        Section("Stream") {
            LabeledContent("Method", value: methodLabel)
            LabeledContent("Requested Cap", value: requestedQuality.title)
            if let mbps = mbpsString(from: info.mediaSource.bitrate) {
                LabeledContent("Delivered Bitrate", value: mbps)
            }
            if let container = deliveredContainer {
                LabeledContent("Container", value: container.uppercased())
            }
        }

        if let videoStream = videoStream {
            Section("Video") {
                if let codec = videoStream.codec {
                    LabeledContent("Codec", value: codecDisplayName(codec))
                }
                if let width = videoStream.width, let height = videoStream.height {
                    LabeledContent(
                        "Resolution",
                        value: "\(width) × \(height) (\(resolutionLabel(width: width, height: height)))"
                    )
                }
                if let mbps = mbpsString(from: videoStream.bitRate) {
                    LabeledContent("Source Bitrate", value: mbps)
                }
                if let fps = videoStream.averageFrameRate ?? videoStream.realFrameRate {
                    LabeledContent("Frame Rate", value: "\(fps.formatted(.number.precision(.fractionLength(0...3)))) fps")
                }
                if let range = videoStream.videoRange?.rawValue {
                    LabeledContent("Range", value: range)
                }
                if let profile = videoStream.profile {
                    let level = videoStream.level.map { " · L\(Int($0))" } ?? ""
                    LabeledContent("Profile", value: "\(profile)\(level)")
                }
            }
        }

        if let audioStream = audioStream {
            Section("Audio") {
                if let codec = audioStream.codec {
                    LabeledContent("Codec", value: codec.uppercased())
                }
                if let channels = audioStream.channels {
                    LabeledContent("Channels", value: audioStream.channelLayout ?? "\(channels)")
                }
                if let sampleRate = audioStream.sampleRate {
                    let khz = Double(sampleRate) / 1000
                    LabeledContent("Sample Rate", value: "\(khz.formatted(.number.precision(.fractionLength(0...1)))) kHz")
                }
                if let language = audioStream.language {
                    LabeledContent("Language", value: language.uppercased())
                }
            }
        }
    }

    private var methodLabel: String {
        switch info.playMethod {
        case .directPlay: "Direct Play"
        case .transcode:  "Transcode"
        }
    }

    private var deliveredContainer: String? {
        if info.playMethod == .transcode {
            return info.mediaSource.transcodingContainer ?? info.mediaSource.container
        }
        return info.mediaSource.container
    }

    private var videoStream: MediaStream? {
        info.mediaSource.mediaStreams?.first(where: { $0.type == .video })
    }

    private var audioStream: MediaStream? {
        let streams = info.mediaSource.mediaStreams ?? []
        if let defaultIndex = info.mediaSource.defaultAudioStreamIndex,
           let match = streams.first(where: { $0.index == defaultIndex && $0.type == .audio }) {
            return match
        }
        return streams.first(where: { $0.type == .audio })
    }

    private func mbpsString(from bps: Int?) -> String? {
        guard let bps, bps > 0 else { return nil }
        let mbps = Double(bps) / 1_000_000
        return "\(mbps.formatted(.number.precision(.fractionLength(1)))) Mbps"
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
