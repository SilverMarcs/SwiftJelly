//
//  DeviceProfile+Native.swift
//  SwiftJelly
//

import Foundation
import JellyfinAPI

extension DeviceProfile {
    
    /// Builds a device profile for native AVPlayer with proper codec and subtitle support
    /// Forces transcoding for all streams and limits resolution to 1080p max
    static func buildNativeProfile() -> DeviceProfile {
        var profile = DeviceProfile()
        
        profile.name = "SwiftJelly Native"
//        profile.maxStreamingBitrate = maxBitrate
//        profile.maxStaticBitrate = maxBitrate
//        profile.musicStreamingTranscodingBitrate = maxBitrate
        
        profile.directPlayProfiles = nativeDirectPlayProfiles
        profile.transcodingProfiles = nativeTranscodingProfiles
        profile.subtitleProfiles = nativeSubtitleProfiles
        profile.codecProfiles = nativeCodecProfiles
        
        return profile
    }
    
    // MARK: - Direct Play Profiles
    
    private static var nativeDirectPlayProfiles: [DirectPlayProfile] {
        [
            DirectPlayProfile(
                audioCodec: nativeVideoAudioCodecList,
                container: "mp4,m4v,mov",
                type: .video,
                videoCodec: "h264,hevc"
            )
        ]
    }
    
    // MARK: - Transcoding Profiles
    
    private static var nativeTranscodingProfiles: [TranscodingProfile] {
        [
            // Primary video+audio stream
            TranscodingProfile(
                audioCodec: nativeVideoAudioCodecList,
                isBreakOnNonKeyFrames: true,
                conditions: [
                    ProfileCondition(
                        condition: .lessThanEqual,
                        isRequired: false,
                        property: .width,
                        value: "1920"
                    ),
                    ProfileCondition(
                        condition: .lessThanEqual,
                        isRequired: false,
                        property: .height,
                        value: "1080"
                    )
                ],
                container: "m3u8",
                context: .streaming,
                isCopyTimestamps: true,
                enableSubtitlesInManifest: true,
                maxAudioChannels: nativeMaxAudioChannels,
                minSegments: 2,
                protocol: .hls,
                type: .video,
                videoCodec: "h264"
            ),

            // Dedicated audio renditions so the manifest can expose named tracks
            TranscodingProfile(
                audioCodec: nativeAudioOnlyCodecList,
                container: "aac",
                context: .streaming,
                isCopyTimestamps: true,
                maxAudioChannels: nativeMaxAudioChannels,
                minSegments: 2,
                protocol: .hls,
                type: .audio
            )
        ]
    }

    // Letting the server downmix 5.1/7.1 → 2ch produces noticeably quiet audio because
    // Jellyfin's downmix doesn't apply loudness compensation. On macOS we let the source
    // keep its native channel count and rely on CoreAudio for downmix when needed.
    // iOS/tvOS/visionOS stay at stereo: tvOS is known to break on 5.1/7.1 AAC, and iOS
    // playback is already at expected loudness without lifting the cap.
    private static var nativeMaxAudioChannels: String {
#if os(tvOS)
        "2"
#else
        "8"
#endif
    }

    private static var nativeVideoAudioCodecList: String {
#if os(iOS)
        "aac,alac"
#else
        "aac,ac3,eac3,alac,flac,dts,opus"
#endif
    }

    private static var nativeAudioOnlyCodecList: String {
#if os(iOS)
        "aac,alac"
#else
        "aac,ac3,eac3,alac,flac,dts,opus"
#endif
    }
    
    // MARK: - Subtitle Profiles
    
    private static var nativeSubtitleProfiles: [SubtitleProfile] {
        [
            // HLS-compatible subtitles (VTT is standard for HLS)
            // We strictly request VTT here so the server forces transcoding of
            // other text formats (SRT, ASS, etc.) to VTT, which AVPlayer supports.
            SubtitleProfile(
                format: "vtt",
                method: .hls
            ),
            // Allow sidecar WebVTT when HLS-in-manifest is unavailable.
            SubtitleProfile(
                format: "vtt",
                method: .external
            ),
            SubtitleProfile(
                format: "srt",
                method: .external
            ),
            // Embedded subtitles in MP4
            SubtitleProfile(
                format: "ttml",
                method: .embed
            )
        ]
    }
    
    // MARK: - Codec Profiles
    
    private static var nativeCodecProfiles: [CodecProfile] {
        [
            CodecProfile(
                applyConditions: [],
                codec: "h264",
                conditions: [
                    ProfileCondition(
                        condition: .lessThanEqual,
                        isRequired: false,
                        property: .videoLevel,
                        value: "51"
                    ),
                    ProfileCondition(
                        condition: .notEquals,
                        isRequired: false,
                        property: .isAnamorphic,
                        value: "true"
                    )
                ],
                type: .video
            )
        ]
    }
}
