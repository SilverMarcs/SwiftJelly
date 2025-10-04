//
//  DeviceProfile+Native.swift
//  SwiftJelly
//

import Foundation
import JellyfinAPI

extension DeviceProfile {
    
    /// Builds a device profile for native AVPlayer with proper codec and subtitle support
    static func buildNativeProfile(maxBitrate: Int = 120_000_000) -> DeviceProfile {
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
            // MP4 container with H264/HEVC and AAC/AC3/EAC3
            DirectPlayProfile(
                audioCodec: "aac,ac3,eac3,alac,flac",
                container: "mp4",
                type: .video,
                videoCodec: "h264,hevc,mpeg4"
            ),
            
            // M4V container
            DirectPlayProfile(
                audioCodec: "aac,ac3,alac",
                container: "m4v",
                type: .video,
                videoCodec: "h264,mpeg4"
            ),
            
            // MOV container
            DirectPlayProfile(
                audioCodec: "aac,ac3,eac3,alac,mp3,pcm_s16be,pcm_s16le,pcm_s24be,pcm_s24le",
                container: "mov",
                type: .video,
                videoCodec: "h264,hevc,mjpeg,mpeg4"
            ),
            
            // MPEG-TS container
            DirectPlayProfile(
                audioCodec: "aac,ac3,eac3,mp3",
                container: "ts,mpegts",
                type: .video,
                videoCodec: "h264"
            ),
            
            // 3GP/3G2 containers
            DirectPlayProfile(
                audioCodec: "aac,amr_nb",
                container: "3gp,3g2",
                type: .video,
                videoCodec: "h264,mpeg4"
            ),
            
            // AVI container
            DirectPlayProfile(
                audioCodec: "pcm_mulaw,pcm_s16le",
                container: "avi",
                type: .video,
                videoCodec: "mjpeg"
            )
        ]
    }
    
    // MARK: - Transcoding Profiles
    
    private static var nativeTranscodingProfiles: [TranscodingProfile] {
        [
            // HLS transcoding with subtitle support
            TranscodingProfile(
                audioCodec: "aac,ac3,eac3,alac,flac",
                isBreakOnNonKeyFrames: true,
                container: "ts",
                context: .streaming,
                enableSubtitlesInManifest: true,  // CRITICAL: Enable subtitles in HLS manifest
                maxAudioChannels: "8",
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
            // HLS-compatible subtitles (delivered as part of HLS stream)
            // Try external first for HLS - this makes subtitles available as separate tracks
            SubtitleProfile(
                format: "vtt",
                method: .hls
            ),
            SubtitleProfile(
                format: "srt",
                method: .external  // External subtitles for text-based formats
            ),
            SubtitleProfile(
                format: "ass",
                method: .external
            ),
            SubtitleProfile(
                format: "ssa",
                method: .external
            ),
            
            // Embedded subtitles (burned into video or embedded in container)
            SubtitleProfile(
                format: "cc_dec",
                method: .embed
            ),
            SubtitleProfile(
                format: "ttml",
                method: .embed
            ),
            
            // Encoded subtitles (image-based, need to be burned in)
            SubtitleProfile(
                format: "dvbsub",
                method: .encode
            ),
            SubtitleProfile(
                format: "dvdsub",
                method: .encode
            ),
            SubtitleProfile(
                format: "pgssub",
                method: .encode
            ),
            SubtitleProfile(
                format: "xsub",
                method: .encode
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
