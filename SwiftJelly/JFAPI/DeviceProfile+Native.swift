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
            // Primary video+audio stream
            TranscodingProfile(
                audioCodec: "aac,ac3,eac3,alac,flac,dts,opus",
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
                maxAudioChannels: nil,
                minSegments: 2,
                protocol: .hls,
                type: .video,
                videoCodec: "h264"
            ),
            // Dedicated audio renditions so the manifest can expose named tracks
            TranscodingProfile(
                audioCodec: "aac,ac3,eac3,alac,flac,dts,opus",
                container: "aac",
                context: .streaming,
                isCopyTimestamps: true,
                maxAudioChannels: nil,
                minSegments: 2,
                protocol: .hls,
                type: .audio
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
