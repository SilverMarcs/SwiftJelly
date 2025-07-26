//
//  UniversalMediaPlayer.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 26/07/2025.
//

import SwiftUI
import JellyfinAPI

struct UniversalMediaPlayer: View {
    let item: BaseItemDto

    var body: some View {
        if AVPlayerSupportChecker.isSupported(item: item) {
            AVMediaPlayerView(item: item)
        } else {
            VLCPlayerView(item: item)
        }
    }
}
