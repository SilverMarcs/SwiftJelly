//
//  DeviceProfile+Native.swift
//  SwiftJelly
//

import Foundation
import JellyfinAPI

extension DeviceProfile {
    
    /// Builds a device profile for native AVPlayer with proper codec and subtitle support
    static func buildNativeProfile(maxBitrate: Int = 10_000_000) -> DeviceProfile {
        var profile = DeviceProfile()
        
        profile.maxStreamingBitrate = maxBitrate
        profile.maxStaticBitrate = maxBitrate
        profile.musicStreamingTranscodingBitrate = maxBitrate
        
        profile.directPlayProfiles = nativeDirectPlayProfiles
         profile.transcodingProfiles = nativeTranscodingProfiles
         profile.subtitleProfiles = nativeSubtitleProfiles
         profile.codecProfiles = nativeCodecProfiles
        
        return profile
    }
    
    // MARK: - Direct Play Profiles
    
    private static var nativeDirectPlayProfiles: [DirectPlayProfile] {
        [
            // MP4 container with H264 and AAC - most compatible with AVPlayer
            DirectPlayProfile(
                audioCodec: "aac",
                container: "mp4",
                type: .video,
                videoCodec: "h264"
            )
        ]
    }
    
    // MARK: - Transcoding Profiles
    
    private static var nativeTranscodingProfiles: [TranscodingProfile] {
        [
            // HLS transcoding with subtitle support
            // Use fMP4 HLS, copy timestamps and prefer AAC stereo to reduce
            // audio/video drift on AVPlayer. Some servers/encoders emit
            // imperfect DTS/PTS when producing MPEG-TS segments which can
            // lead to audio drifting vs video in AVPlayer for certain files.
            TranscodingProfile(
                audioCodec: "aac,ac3,eac3,alac,flac",
                isBreakOnNonKeyFrames: true,
                // Request fragmented MP4 segments (fMP4) for HLS instead of
                // MPEG-TS. fMP4 often has better timestamp handling for
                // AVPlayer and reduces sync issues.
//                container: "mp4",
                context: .streaming,
                // Copy timestamps from source where possible to preserve PTS/DTS
                isCopyTimestamps: true,
                enableSubtitlesInManifest: true,  // CRITICAL: Enable subtitles in HLS manifest
                // Prefer stereo audio unless multichannel is required. This
                // reduces transcoding choices that might introduce timing
                // issues on some encoders/clients.
                maxAudioChannels: "2",
                minSegments: 2,
                protocol: .hls,
                type: .video,
                videoCodec: "h264,hevc,mpeg4"
            )
        ]
    }
    
    // MARK: - Subtitle Profiles
    
    private static var nativeSubtitleProfiles: [SubtitleProfile] {
        [
            // HLS-compatible subtitles
            SubtitleProfile(
                format: "vtt",
                method: .hls
            ),
            // External text subtitles
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
