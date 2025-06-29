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
    @Published var users: [User] = []
    @Published var currentUser: User?
    
    static let shared = DataManager()
    
    private let serversKey = "SavedServers"
    private let usersKey = "SavedUsers"
    private let currentUserKey = "CurrentUser"
    
    init() {
        loadData()
    }
    
    func addServer(_ server: Server) {
        servers.append(server)
        saveServers()
    }
    
    func removeServer(_ server: Server) {
        servers.removeAll { $0.id == server.id }
        users.removeAll { $0.serverID == server.id }
        if currentUser?.serverID == server.id {
            currentUser = nil
            saveCurrentUser()
        }
        saveServers()
        saveUsers()
    }
    
    func addUser(_ user: User) {
        users.append(user)
        saveUsers()
    }
    
    func updateUserToken(_ user: User, token: String) {
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index].accessToken = token
            saveUsers()
        }
    }
    
    func signIn(user: User) {
        currentUser = user
        saveCurrentUser()
    }
    
    func signOut() {
        currentUser = nil
        saveCurrentUser()
    }
    
    func getServer(for user: User) -> Server? {
        return servers.first { $0.id == user.serverID }
    }
    
    private func loadData() {
        loadServers()
        loadUsers()
        loadCurrentUser()
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
    
    private func loadUsers() {
        if let data = UserDefaults.standard.data(forKey: usersKey),
           let users = try? JSONDecoder().decode([User].self, from: data) {
            self.users = users
        }
    }
    
    private func saveUsers() {
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: usersKey)
        }
    }
    
    private func loadCurrentUser() {
        if let data = UserDefaults.standard.data(forKey: currentUserKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            self.currentUser = user
        }
    }
    
    private func saveCurrentUser() {
        if let currentUser = currentUser,
           let data = try? JSONEncoder().encode(currentUser) {
            UserDefaults.standard.set(data, forKey: currentUserKey)
        } else {
            UserDefaults.standard.removeObject(forKey: currentUserKey)
        }
    }
}
