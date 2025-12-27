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
        WindowGroup("Media Player", id: "media-player", for: BaseItemDto.self) { $item in
            if let item = item {
                AVMediaPlayerViewMac(item: item)
            }
        }
        .defaultSize(width: 1024, height: 576)
        .restorationBehavior(.disabled)
        #endif
    }
    
    init() {
        AVPlayer.isObservationEnabled = true
        #if !os(macOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        #endif
    }
}
