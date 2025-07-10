//
//  AVPlayerIos.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import AVKit

struct AVPlayerIos: UIViewControllerRepresentable {
    let player: AVPlayer
    let startTimeSeconds: Int
    let stateManager: AVPlayerStateManager
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.entersFullScreenWhenPlaybackBegins = true
        controller.exitsFullScreenWhenPlaybackEnds = true
        controller.modalPresentationStyle = .fullScreen
        controller.allowsPictureInPicturePlayback = true
        
        // Set up state manager
        stateManager.setPlayer(player)
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        let time = CMTime(seconds: Double(startTimeSeconds), preferredTimescale: 1)
        uiViewController.player?.seek(to: time)
        uiViewController.player?.play()
    }
}
