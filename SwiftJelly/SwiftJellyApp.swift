//
//  SwiftJellyApp.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import JellyfinAPI
import AVKit

@main
struct SwiftJellyApp: App {
    @State var selectedTab: TabSelection = .home
    
    var body: some Scene {
        WindowGroup {
            ContentView(selectedTab: $selectedTab)
        }
        #if !os(tvOS)
        .commands {
            AppCommands(selectedTab: $selectedTab)
        }
        #endif
        
        #if os(macOS)
        Window("Media Player", id: "media-player") {
            AVMediaPlayerViewMac()
        }
        .defaultSize(width: 1024, height: 576)
        .restorationBehavior(.disabled)
        #endif
    }
    
    init() {
        AVPlayer.isObservationEnabled = true
        #if !os(macOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback)
        try? session.setActive(true)
        #endif
        _ = PlaybackManager.shared
        _ = SeerrAuth.shared
        #if os(iOS)
        // Register BGContinuedProcessingTask handler before any submit() call.
        DownloadActivityCoordinator.register()
        // Eagerly init so the manager is ready when the first download starts.
        _ = DownloadManager.shared
        #endif
    }
}
