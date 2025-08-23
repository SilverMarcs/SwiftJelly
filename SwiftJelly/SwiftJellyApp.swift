//
//  SwiftJellyApp.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import JellyfinAPI

@main
struct SwiftJellyApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        #if os(macOS)
        WindowGroup("Media Player", id: "media-player", for: MediaItem.self) { $mediaItem in
            if let mediaItem = mediaItem {
                UniversalMediaPlayer(mediaItem: mediaItem)
            } else {
                Text("Unable to open player window.")
            }
        }
        .restorationBehavior(.disabled)
        .windowResizability(.contentSize)
        
//        Settings {
//            SettingsView()
//        }
        #endif
    }
}
