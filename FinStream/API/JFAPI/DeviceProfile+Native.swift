//
//  DeviceProfile+Native.swift
//  SwiftJelly
//

import Foundation
import JellyfinAPI

extension DeviceProfile {
    
    /// Builds a device profile for native AVPlayer with proper codec and subtitle support
    static func buildNativeProfile() -> DeviceProfile {
        var profile = DeviceProfile()
        
        profile.name = "FinStream Native"
        
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
                audioCodec: JellyfinPlaybackPolicy.audioCodecs,
                container: "mp4,m4v,mov",
                type: .video,
                videoCodec: JellyfinPlaybackPolicy.videoCodecs
            )
        ]
    }
    
    // MARK: - Transcoding Profiles
    
    private static var nativeTranscodingProfiles: [TranscodingProfile] {
        [
            // Primary video+audio stream
            TranscodingProfile(
                audioCodec: JellyfinPlaybackPolicy.audioCodecs,
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
                maxAudioChannels: String(JellyfinPlaybackPolicy.maxAudioChannels),
                minSegments: JellyfinPlaybackPolicy.minSegments,
                protocol: .hls,
                segmentLength: JellyfinPlaybackPolicy.segmentLength,
                type: .video,
                videoCodec: JellyfinPlaybackPolicy.legacyHLSVideoCodecs
            )
        ]
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
