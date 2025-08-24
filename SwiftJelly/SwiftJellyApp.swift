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
    
    @State private var localMediaManager = LocalMediaManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(localMediaManager)
        }
        
        #if os(macOS)
        WindowGroup("Media Player", id: "media-player", for: MediaItem.self) { $mediaItem in
            if let mediaItem = mediaItem {
                UniversalMediaPlayer(mediaItem: mediaItem)
                    .environment(localMediaManager)
            } else {
                Text("Unable to open player window.")
                    .environment(localMediaManager)
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
