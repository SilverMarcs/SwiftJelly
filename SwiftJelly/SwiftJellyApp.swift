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
    @StateObject private var dataManager = DataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
#if os(macOS)
        WindowGroup("Media Player", id: "media-player", for: BaseItemDto.self) { $item in
            if let item = item {
                MediaPlayerView(item: item)
            } else {
                Text("Unable to open player window.")
            }
        }
        .restorationBehavior(.disabled)
#endif
    }
}
