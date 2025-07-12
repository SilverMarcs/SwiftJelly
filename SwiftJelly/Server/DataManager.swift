//
//  DataManager.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import Foundation
import SwiftUI
import JellyfinAPI

@Observable class DataManager {
    var servers: [Server] = []
    var activeServerID: String?
    
    @ObservationIgnored static let shared = DataManager()

    @ObservationIgnored private let serversKey = "SavedServers"
    @ObservationIgnored private let activeServerKey = "ActiveServerID"

    init() {
        loadServers()
    }

    var server: Server? {
        servers.first(where: { $0.id == activeServerID })
    }

    func addServer(_ server: Server) {
        servers.append(server)
        saveServers()
    }

    func updateServer(_ server: Server) {
        if let idx = servers.firstIndex(where: { $0.id == server.id }) {
            servers[idx] = server
            saveServers()
        }
    }

    func deleteServer(_ server: Server) {
        servers.removeAll { $0.id == server.id }
        if activeServerID == server.id {
            activeServerID = servers.first?.id
        }
        saveServers()
    }

    func selectServer(_ server: Server) {
        activeServerID = server.id
        saveServers()
    }

    private func loadServers() {
        if let data = UserDefaults.standard.data(forKey: serversKey),
           let decoded = try? JSONDecoder().decode([Server].self, from: data) {
            self.servers = decoded
        }
        self.activeServerID = UserDefaults.standard.string(forKey: activeServerKey) ?? servers.first?.id
    }

    private func saveServers() {
        if let data = try? JSONEncoder().encode(servers) {
            UserDefaults.standard.set(data, forKey: serversKey)
        }
        UserDefaults.standard.set(activeServerID, forKey: activeServerKey)
    }
}
