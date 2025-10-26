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
    #endif
    
    @State var selectedTab: TabSelection = .home
    
    var body: some Scene {
        #if os(macOS)
        Window("SwiftJelly", id: "swiftjelly") {
            ContentView(selectedTab: $selectedTab)
        }
        .commands {
            AppCommands(selectedTab: $selectedTab)
        }
        
        WindowGroup("Media Player", id: "media-player", for: BaseItemDto.self) { $item in
            if let item = item {
                AVMediaPlayerView(item: item)
                    .windowFullScreenBehavior(.disabled)
                    .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                    .gesture(WindowDragGesture())
            } else {
                Text("Unable to open player window.")
            }
        }
        .restorationBehavior(.disabled)
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
