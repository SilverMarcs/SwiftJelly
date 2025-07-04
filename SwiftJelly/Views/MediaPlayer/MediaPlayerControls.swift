//
//  MediaPlayerControls.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 29/06/2025.
//

import SwiftUI
import VLCUI

/// Reusable media player control buttons (play/pause, seek forward/backward)
struct MediaPlayerControls: View {
    @ObservedObject var playbackState: PlaybackStateManager
    var proxy: VLCVideoPlayer.Proxy

    var body: some View {
        HStack(spacing: 40) {
            Button(action: { proxy.jumpBackward(10) }) {
                Image(systemName: "gobackward.5")
                    .font(.system(size: 25))
                    .padding(10)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular, in: .rect(cornerRadius: 30))

            Button {
                if playbackState.isPlaying {
                    proxy.pause()
                } else {
                    proxy.play()
                }
            } label: {
                Image(systemName: playbackState.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 40))
                    .padding(15)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular, in: .rect(cornerRadius: 30))
            

            Button(action: { proxy.jumpForward(10) }) {
                Image(systemName: "goforward.5")
                    .font(.system(size: 25))
                    .padding(10)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular, in: .rect(cornerRadius: 30))
        }
    }
}
