//
//  User.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: String
    let serverID: String
    var username: String
    var accessToken: String?
    
    init(id: String = UUID().uuidString, serverID: String, username: String, accessToken: String? = nil) {
        self.id = id
        self.serverID = serverID
        self.username = username
        self.accessToken = accessToken
    }
}
