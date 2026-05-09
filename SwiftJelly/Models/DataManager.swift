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
    @ObservationIgnored private let migrationKey = "DataManager.iCloudMigrated"
    @ObservationIgnored private let defaults = UserDefaults.standard

    init() {
        migrateFromICloudIfNeeded()
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
        if let data = defaults.data(forKey: serversKey),
           let decoded = try? JSONDecoder().decode([Server].self, from: data) {
            self.servers = decoded
        }
        self.activeServerID = defaults.string(forKey: activeServerKey) ?? servers.first?.id
    }

    private func saveServers() {
        if let data = try? JSONEncoder().encode(servers) {
            defaults.set(data, forKey: serversKey)
        }
        defaults.set(activeServerID, forKey: activeServerKey)
    }

    private func migrateFromICloudIfNeeded() {
        guard !defaults.bool(forKey: migrationKey) else { return }
        let kvs = NSUbiquitousKeyValueStore.default
        kvs.synchronize()
        if defaults.data(forKey: serversKey) == nil, let data = kvs.data(forKey: serversKey) {
            defaults.set(data, forKey: serversKey)
        }
        if defaults.string(forKey: activeServerKey) == nil, let active = kvs.string(forKey: activeServerKey) {
            defaults.set(active, forKey: activeServerKey)
        }
        defaults.set(true, forKey: migrationKey)
    }
}
