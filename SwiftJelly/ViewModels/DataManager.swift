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
    @Published var server: Server?

    static let shared = DataManager()

    private let serverKey = "SavedServer"

    init() {
        loadServer()
    }

    func setServer(_ server: Server) {
        self.server = server
        saveServer()
    }

    func updateServer(_ updatedServer: Server) {
        self.server = updatedServer
        saveServer()
    }

    func clearServer() {
        self.server = nil
        UserDefaults.standard.removeObject(forKey: serverKey)
    }

    func authenticateServer(username: String, accessToken: String, jellyfinUserID: String) {
        guard var currentServer = server else { return }
        currentServer.username = username
        currentServer.accessToken = accessToken
        currentServer.jellyfinUserID = jellyfinUserID
        updateServer(currentServer)
    }

    var isAuthenticated: Bool {
        return server?.isAuthenticated ?? false
    }

    private func loadServer() {
        if let data = UserDefaults.standard.data(forKey: serverKey),
           let server = try? JSONDecoder().decode(Server.self, from: data) {
            self.server = server
        }
    }

    private func saveServer() {
        if let server = server,
           let data = try? JSONEncoder().encode(server) {
            UserDefaults.standard.set(data, forKey: serverKey)
        }
    }
}
