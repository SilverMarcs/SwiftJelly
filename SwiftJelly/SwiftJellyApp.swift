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
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

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
        // Eagerly attach to the background URLSession so any in-flight downloads
        // resume reporting to our delegate as soon as the app launches.
        _ = DownloadManager.shared
        #endif
    }
}
