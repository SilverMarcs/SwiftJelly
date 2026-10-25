import Foundation
import JellyfinAPI

/// The same capabilities and HLS choices drive negotiation and adaptation.
enum JellyfinPlaybackPolicy {
    static let videoCodecs = "h264,hevc"
    // The legacy negotiated HLS profile can use TS; HEVC stays in fMP4.
    static let legacyHLSVideoCodecs = "h264"
    static let audioCodecs = "aac,ac3,eac3,alac,flac,dts,opus"
    static let hlsAudioCodec = "aac"
    static let hlsAudioBitrate = 384_000
    // Preserve surround channels and let CoreAudio handle speaker downmixing.
    static let maxAudioChannels = 8
    static let minSegments = 2
    static let segmentLength = 6
    static let segmentContainer = "mp4"

    static func hlsURL(context: JFAPI.APIContext, info: PlaybackInfoResponse, sessionID: String, audioIndex: Int?, subtitleIndex: Int?) throws -> URL {
        var components = URLComponents(url: context.server.url.appending(path: "Videos/\(info.itemID)/master.m3u8"), resolvingAgainstBaseURL: false)
        var query = URLComponents(url: info.playbackURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let overrides = [
            "MediaSourceId": info.mediaSource.id ?? info.itemID,
            "DeviceId": context.server.id,
            "PlaySessionId": sessionID,
            "api_key": context.client.accessToken ?? "",
            "AudioStreamIndex": audioIndex.map(String.init),
            "SubtitleStreamIndex": subtitleIndex.map(String.init),
            "AudioCodec": hlsAudioCodec,
            "AudioBitRate": String(hlsAudioBitrate),
            "MaxAudioChannels": String(maxAudioChannels),
            "AllowAudioStreamCopy": "false",
            "AllowVideoStreamCopy": "true",
            "VideoCodec": videoCodecs,
            "SegmentContainer": segmentContainer,
            "SegmentLength": String(segmentLength),
            "MinSegments": String(minSegments),
            "CopyTimestamps": "true",
            "StartTimeTicks": "0",
            "EnableSubtitlesInManifest": "true",
            "SubtitleMethod": "Hls",
            "SubtitleCodec": "vtt",
            "Static": "false"
        ]
        let keys = Set(overrides.keys.map { $0.lowercased() })
        query.removeAll { keys.contains($0.name.lowercased()) }
        query += overrides.compactMap { key, value in value.map { URLQueryItem(name: key, value: $0) } }
        if !query.contains(where: { $0.name.lowercased() == "videobitrate" }) {
            let bitrate = info.mediaSource.mediaStreams?.first(where: { $0.type == .video })?.bitRate ?? 20_000_000
            query.append(URLQueryItem(name: "VideoBitRate", value: String(bitrate)))
        }
        components?.queryItems = query
        guard let url = components?.url else { throw PlaybackError.invalidTranscodeURL }
        return url
    }
}
