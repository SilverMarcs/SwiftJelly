//
//  AVPlayerMac.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import AVKit
import AppKit

struct AVPlayerMac<Overlay: View>: NSViewRepresentable {
    let player: AVPlayer?
    let overlay: Overlay

    init(player: AVPlayer?) where Overlay == EmptyView {
        self.player = player
        self.overlay = EmptyView()
    }

    init(player: AVPlayer?, @ViewBuilder overlay: () -> Overlay) {
        self.player = player
        self.overlay = overlay()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .floating
        view.showsFullScreenToggleButton = true
        view.allowsPictureInPicturePlayback = true
        context.coordinator.installOverlay(in: view, rootView: overlay)
        
        return view
    } 
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
        context.coordinator.updateOverlay(rootView: overlay)
    }

    final class Coordinator {
        var hostingView: NSHostingView<Overlay>?

        func installOverlay(in playerView: AVPlayerView, rootView: Overlay) {
            if let hostingView {
                hostingView.rootView = rootView
                return
            }

            let container = playerView.contentOverlayView ?? playerView
            let hostingView = NSHostingView(rootView: rootView)
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(hostingView)

            NSLayoutConstraint.activate([
                hostingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                hostingView.topAnchor.constraint(equalTo: container.topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])

            self.hostingView = hostingView
        }

        func updateOverlay(rootView: Overlay) {
            hostingView?.rootView = rootView
        }
    }
}
