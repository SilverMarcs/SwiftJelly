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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        #if os(macOS)
        WindowGroup("Media Player", id: "media-player", for: BaseItemDto.self) { $item in
            if let item = item {
                AVMediaPlayerView(item: item)
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
