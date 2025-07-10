//
//  MediaPlayerProgressBar.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 29/06/2025.
//

import SwiftUI
import VLCUI

/// Reusable media player progress bar with time labels and seek slider
struct VLCPlayerProgressBar: View {
    @ObservedObject var playbackState: PlaybackStateManager
    var proxy: VLCVideoPlayer.Proxy

    var body: some View {
        HStack {
            Text(playbackState.currentSeconds.formattedTime)
                .font(.caption)
                .monospacedDigit()

            Slider(
                value: Binding(
                    get: { playbackState.isSeeking ? playbackState.seekValue : Double(playbackState.currentSeconds) },
                    set: { newValue in
                        playbackState.startSeeking(to: newValue)
                    }
                ),
                in: 0...Double(playbackState.totalSeconds),
                onEditingChanged: { editing in
                    if editing {
                        // User started seeking
                    } else {
                        // User finished seeking
                        let seekPosition = playbackState.endSeeking()
                        proxy.setSeconds(.seconds(Int64(seekPosition)))
                    }
                }
            )

            Text(playbackState.totalSeconds.formattedTime)
                .font(.caption)
                .monospacedDigit()
        }
    }
}
