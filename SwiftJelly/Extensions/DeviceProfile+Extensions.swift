//
//  DeviceProfile+Extensions.swift
//  SwiftJelly
//
//  Created by GitHub Copilot on 04/07/2025.
//

import Foundation
import JellyfinAPI

extension DeviceProfile {
    
    /// Creates a basic device profile for VLC player with subtitle support
    static func createBasicVLCProfile(maxBitrate: Int? = nil) -> DeviceProfile {
        var profile = DeviceProfile()
        
        // Basic identification
        profile.name = "SwiftJelly VLC"
        profile.maxStreamingBitrate = maxBitrate
        profile.maxStaticBitrate = maxBitrate
        
        // Subtitle profiles - this is crucial for getting external subtitle delivery URLs
        profile.subtitleProfiles = [
            SubtitleProfile(
                format: "srt",
                method: .external
            ),
            SubtitleProfile(
                format: "ass",
                method: .external
            ),
            SubtitleProfile(
                format: "ssa",
                method: .external
            ),
            SubtitleProfile(
                format: "vtt",
                method: .external
            ),
            SubtitleProfile(
                format: "sub",
                method: .external
            ),
            SubtitleProfile(
                format: "idx",
                method: .external
            )
        ]
        
        // Basic direct play profiles for video
        profile.directPlayProfiles = [
            DirectPlayProfile(
                container: "mp4,mkv,avi,mov,wmv,asf,webm",
                type: .video
            ),
            DirectPlayProfile(
                container: "mp3,flac,aac,ogg,oga,wav,wma,m4a",
                type: .audio
            )
        ]
        
        // Basic transcoding profiles
        profile.transcodingProfiles = [
            TranscodingProfile(
                audioCodec: "aac,mp3",
                isBreakOnNonKeyFrames: true,
                container: "mp4",
                type: .video,
                videoCodec: "h264"
            )
        ]
        
        return profile
    }
}
