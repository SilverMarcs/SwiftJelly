//
//  SwiftJellyApp.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI

@main
struct SwiftJellyApp: App {
    @StateObject private var dataManager = DataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
#if os(macOS)
        WindowGroup("Continue Watching Player", id: "continue-watching-player", for: ContinueWatchingPlayerWindowData.self) { $data in
            if let data = data,
               let server = dataManager.servers.first(where: { $0.id == data.serverId }),
               let user = dataManager.users.first(where: { $0.id == data.userId }) {
                ContinueWatchingPlayerWindowView(item: data.item, server: server, user: user)
            } else {
                Text("Unable to open player window.")
            }
        }
#endif
    }
}
