//
//  DataManager.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import Foundation
import SwiftUI
import Combine
import JellyfinAPI

class DataManager: ObservableObject {
    @Published var servers: [Server] = []
    @Published var currentServer: Server?

    static let shared = DataManager()

    private let serversKey = "SavedServers"
    private let currentServerKey = "CurrentServer"
    
    init() {
        loadData()
    }

    func addServer(_ server: Server) {
        servers.append(server)
        saveServers()
    }

    func updateServer(_ server: Server) {
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = server
            saveServers()

            // Update current server if it's the one being updated
            if currentServer?.id == server.id {
                currentServer = server
                saveCurrentServer()
            }
        }
    }

    func removeServer(_ server: Server) {
        servers.removeAll { $0.id == server.id }
        if currentServer?.id == server.id {
            currentServer = nil
            saveCurrentServer()
        }
        saveServers()
    }
    
    func authenticateServer(_ server: Server, username: String, accessToken: String, jellyfinUserID: String) {
        var updatedServer = server
        updatedServer.username = username
        updatedServer.accessToken = accessToken
        updatedServer.jellyfinUserID = jellyfinUserID
        updateServer(updatedServer)
    }

    func signIn(server: Server) {
        currentServer = server
        saveCurrentServer()
    }

    func signOut() {
        currentServer = nil
        saveCurrentServer()
    }
    
    private func loadData() {
        loadServers()
        loadCurrentServer()
    }

    private func loadServers() {
        if let data = UserDefaults.standard.data(forKey: serversKey),
           let servers = try? JSONDecoder().decode([Server].self, from: data) {
            self.servers = servers
        }
    }

    private func saveServers() {
        if let data = try? JSONEncoder().encode(servers) {
            UserDefaults.standard.set(data, forKey: serversKey)
        }
    }

    private func loadCurrentServer() {
        if let data = UserDefaults.standard.data(forKey: currentServerKey),
           let server = try? JSONDecoder().decode(Server.self, from: data) {
            self.currentServer = server
        }
    }

    private func saveCurrentServer() {
        if let currentServer = currentServer,
           let data = try? JSONEncoder().encode(currentServer) {
            UserDefaults.standard.set(data, forKey: currentServerKey)
        } else {
            UserDefaults.standard.removeObject(forKey: currentServerKey)
        }
    }
}
