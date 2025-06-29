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
    let isPlaying: Bool
    let onPlayPause: () -> Void
    let onSeekBackward: () -> Void
    let onSeekForward: () -> Void
    
    var body: some View {
        HStack(spacing: 40) {
            Button(action: onSeekBackward) {
                Image(systemName: "gobackward.5")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            .buttonStyle(.glass)
            
            Button(action: onPlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            .buttonStyle(.glass)
            
            Button(action: onSeekForward) {
                Image(systemName: "goforward.5")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            .buttonStyle(.glass)
        }
    }
}
