//
//  VLCMobileControls.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 26/07/2025.
//

import SwiftUI
import VLCUI

struct VLCMobileControls: View {
    let playbackState: PlaybackStateManager
    let proxy: VLCVideoPlayer.Proxy
    @Binding var controlsVisible: Bool
    
    var body: some View {
        HStack(spacing: 30) {
            if controlsVisible {
                Button {
                    proxy.jumpBackward(10)
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 25))
                        .padding(5)
                }
            }
            
            Button {
                if playbackState.isPlaying {
                    proxy.pause()
                } else {
                    proxy.play()
                }
            } label: {
                Image(systemName: playbackState.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 45))
                    .padding(10)
            }
            .opacity(controlsVisible ? 1 : 0.01)
            .contentShape(Rectangle()) // Always has a tappable area
            .allowsHitTesting(true)
            
            if controlsVisible {
                Button {
                    proxy.jumpForward(10)
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 25))
                        .padding(5)
                }
            }
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
    }
}
