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
    let controlsVisible: Bool
    
    var body: some View {
        HStack(spacing: 30) {
            if controlsVisible {
                Button {
                    proxy.jumpBackward(.seconds(10))
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 27))
                        .padding(7)
                }
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
                    .contentTransition(.symbolEffect(.replace))
                    .font(.system(size: 49))
                    .padding(14)
            }
            .opacity(controlsVisible ? 1 : 0.001)
            .contentShape(Rectangle())
            .allowsHitTesting(true)
            
            if controlsVisible {
                Button {
                    proxy.jumpForward(.seconds(10))
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 27))
                        .padding(7)
                }
            }
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
    }
}
