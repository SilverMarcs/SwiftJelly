//
//  AVPlayerMac.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import AVKit

struct AVPlayerMac: NSViewRepresentable {
    let startTimeSeconds: Int
    let player: AVPlayer
    
    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .floating
        view.showsFullScreenToggleButton = true
        
        // Do initial seek and play once
        let time = CMTime(seconds: Double(startTimeSeconds), preferredTimescale: 1)
        view.player?.seek(to: time)
        view.player?.play()
        
        return view
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        
    }
}
