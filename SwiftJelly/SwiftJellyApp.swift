//
//  SwiftJellyApp.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

@main
struct SwiftJellyApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #else
    @State private var localMediaManager = LocalMediaManager()
    #endif
    
    @State var selectedTab: TabSelection = .home
    
    var body: some Scene {
        #if os(macOS)
        Window("SwiftJelly", id: "swiftjelly") {
            ContentView(selectedTab: $selectedTab)
                .environment(localMediaManager)
        }
        .commands {
            AppCommands(selectedTab: $selectedTab)
        }
        
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
        
        #else
        WindowGroup {
            ContentView(selectedTab: $selectedTab)
        }
        #endif
    }
    
    init() {
         CachedAsyncImageConfiguration.configure(
             memoryCostLimitMB: 100,       // Max 100 MB memory usage
             diskCacheLimitMB: 400         // Max 500 MB disk cache
         )
    }
}
