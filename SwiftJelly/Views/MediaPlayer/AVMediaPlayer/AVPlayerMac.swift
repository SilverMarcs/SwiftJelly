//
//  AVPlayerMac.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import AVKit

struct AVPlayerMac: NSViewRepresentable {
    let player: AVPlayer?
    
    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        if let player {
            view.player = player
            view.player?.preventsDisplaySleepDuringVideoPlayback = true
        }
//        view.videoGravity = .resizeAspectFill
        view.controlsStyle = .floating
        view.showsFullScreenToggleButton = true
        view.allowsPictureInPicturePlayback = true
        
        return view
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }
}
