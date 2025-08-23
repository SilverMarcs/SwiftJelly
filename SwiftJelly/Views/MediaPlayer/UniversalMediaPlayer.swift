//
//  UniversalMediaPlayer.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 26/07/2025.
//

import SwiftUI
import JellyfinAPI

struct UniversalMediaPlayer: View {
    let mediaItem: MediaItem
    
    // Convenience initializer for Jellyfin items (backward compatibility)
    init(item: BaseItemDto) {
        self.mediaItem = .jellyfin(item)
    }
    
    init(mediaItem: MediaItem) {
        self.mediaItem = mediaItem
    }

    var body: some View {
        switch mediaItem {
        case .jellyfin(let item):
            if AVPlayerSupportChecker.isSupported(item: item) {
                AVMediaPlayerView(item: item)
            } else {
                VLCPlayerView(mediaItem: mediaItem)
            }
        case .local:
            // Always use VLC for local files for broader format support
            // TODO: dont do this, still try for avplayer
            VLCPlayerView(mediaItem: mediaItem)
        }
    }
}
