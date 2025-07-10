//
//  Server.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import Foundation

struct Server: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var url: URL

    // User authentication data
    var username: String?
    var accessToken: String?
    var jellyfinUserID: String? // The actual Jellyfin user ID from authentication

    // Computed property to check if user is authenticated
    var isAuthenticated: Bool {
        return username != nil && accessToken != nil && jellyfinUserID != nil
    }

    init(id: String = UUID().uuidString, name: String, url: URL, username: String? = nil, accessToken: String? = nil, jellyfinUserID: String? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.username = username
        self.accessToken = accessToken
        self.jellyfinUserID = jellyfinUserID
    }
}
