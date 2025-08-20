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
                proxy.jumpBackward(10)
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.title2)
            }
            
            Button {
                if playbackState.isPlaying {
                    proxy.pause()
                } else {
                    proxy.play()
                }
            } label: {
                Image(systemName: playbackState.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title)
                    .frame(width: 25, height: 25) 
            }
            
            Button {
                proxy.jumpForward(10)
            } label: {
                Image(systemName: "goforward.10")
                    .font(.title2)
            }
            #endif
            
            // Time and slider
            Text(timeString(from: playbackState.currentSeconds))
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

            Text(timeString(from: playbackState.totalDuration))
                .font(.caption)
                .monospacedDigit()
            
            // Subtitle picker - always show for debugging
            VLCSubtitlePicker(subtitleManager: subtitleManager)
        }
        .buttonStyle(.plain)
        #if os(macOS)
        .frame(maxWidth: 500)
        #endif
        .padding(12)
        .glassEffect()
    }
    
    private func timeString(from seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
