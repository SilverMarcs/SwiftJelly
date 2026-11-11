//
//  AVPlayerIos.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import AVKit

/// Shows the playback's shared player view controller.
struct AVPlayerIos: UIViewControllerRepresentable {
    let player: AVPlayer?
    let host: PlayerViewControllerHost

    func makeUIViewController(context: Context) -> PlayerContainerViewController {
        host.setPlayer(player)
        return PlayerContainerViewController(host: host)
    }

    func updateUIViewController(_ uiViewController: PlayerContainerViewController, context: Context) {
        host.setPlayer(player)
    }

    static func dismantleUIViewController(_ uiViewController: PlayerContainerViewController, coordinator: ()) {
        uiViewController.releasePlayerViewController()
    }
}
