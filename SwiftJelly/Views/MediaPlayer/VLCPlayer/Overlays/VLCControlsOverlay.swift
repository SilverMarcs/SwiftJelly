//
//  VLCControlsOverlay.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 26/07/2025.
//

import SwiftUI
import VLCUI

struct VLCControlsOverlay: View {
    let playbackState: PlaybackStateManager
    let proxy: VLCVideoPlayer.Proxy
    let subtitleManager: SubtitleManager
    
    @State private var isDragging = false
    @State private var dragProgress: Double = 0
    
    var body: some View {
        HStack(spacing: 15) {
            #if os(macOS)
            // Control buttons
            Button {
                proxy.jumpBackward(.seconds(10))
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.title2)
            }
            
            Button {
                playbackState.isPlaying.toggle()
                if playbackState.isPlaying {
                    proxy.play()
                } else {
                    proxy.pause()
                }
            } label: {
                Image(systemName: playbackState.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title)
                    .frame(width: 25, height: 25) 
            }
            
            Button {
                proxy.jumpForward(.seconds(10))
            } label: {
                Image(systemName: "goforward.10")
                    .font(.title2)
            }
            #endif
            
            // Time and slider
            Text(playbackState.currentSeconds.timeString())
                .font(.caption)
                .monospacedDigit()

            Slider(
                value: $dragProgress,
                in: 0...1,
                onEditingChanged: { editing in
                    if editing {
                        isDragging = true
                    } else {
                        let newSeconds = Int(dragProgress * Double(playbackState.totalDuration))
                        proxy.setSeconds(.seconds(newSeconds))
                        isDragging = false
                    }
                }
            )
            .onAppear {
                dragProgress = playbackState.currentProgress
            }
            .onChange(of: playbackState.currentProgress) {
                if !isDragging {
                    dragProgress = playbackState.currentProgress
                }
            }

            Text(playbackState.totalDuration.timeString())
                .font(.caption)
                .monospacedDigit()
            
            // Subtitle picker - always show for debugging
            VLCSubtitlePicker(subtitleManager: subtitleManager)
        }
        .buttonStyle(.plain)
        #if os(macOS)
        .frame(maxWidth: 500)
        #endif
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .glassEffect()
    }
}
