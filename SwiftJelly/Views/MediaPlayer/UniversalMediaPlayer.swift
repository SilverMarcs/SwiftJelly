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
    
    init(mediaItem: MediaItem) {
        self.mediaItem = mediaItem
    }

    var body: some View {
        if AVPlayerSupportChecker.isSupported(item: mediaItem) {
            AVMediaPlayerView(mediaItem: mediaItem)
        } else {
            VLCPlayerView(mediaItem: mediaItem)
        }
    }
}
