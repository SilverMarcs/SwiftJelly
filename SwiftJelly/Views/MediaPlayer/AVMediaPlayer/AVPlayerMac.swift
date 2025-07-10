//
//  AVPlayerMac.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import AVKit

struct AVPlayerMac: NSViewRepresentable {
    let player: AVPlayer
    let startTimeSeconds: Int
    let stateManager: AVPlayerStateManager
    
    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .floating
        view.allowsPictureInPicturePlayback = true
//        view.showsFullScreenToggleButton = true
        
        // Set up state manager
        stateManager.setPlayer(player)
        
        return view
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        let time = CMTime(seconds: Double(startTimeSeconds), preferredTimescale: 1)
        nsView.player?.seek(to: time)
        nsView.player?.play()
    }
}
