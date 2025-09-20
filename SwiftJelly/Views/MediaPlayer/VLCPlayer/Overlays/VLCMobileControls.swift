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
    
    var body: some View {
        HStack(spacing: 30) {
            Button {
                proxy.jumpBackward(10)
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 27))
                    .padding(7)
            }
            
            Button {
                if playbackState.isPlaying {
                    proxy.pause()
                } else {
                    proxy.play()
                }
            } label: {
                Image(systemName: playbackState.isPlaying ? "pause.fill" : "play.fill")
                    .contentTransition(.symbolEffect(.replace))
                    .font(.system(size: 49))
                    .padding(14)
            }
            
            Button {
                proxy.jumpForward(10)
            } label: {
                Image(systemName: "goforward.10")
                    .font(.system(size: 27))
                    .padding(7)
            }
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
    }
}