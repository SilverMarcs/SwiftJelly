//
//  SeerAccount.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

struct SeerAccount: Codable, Hashable {
    var url: URL
    var authMethod: SeerAuthMethod
    var username: String
    var sessionCookie: String?
    var userID: Int?
    var displayName: String?

    var isAuthenticated: Bool {
        sessionCookie != nil && userID != nil
    }
}

enum SeerAuthMethod: String, Codable, CaseIterable, Identifiable {
    case jellyfin
    case local

    var id: String { rawValue }

    var title: String {
        switch self {
        case .jellyfin: "Jellyfin Account"
        case .local: "Local Account"
        }
    }

    var usernamePrompt: String {
        switch self {
        case .jellyfin: "Username"
        case .local: "Email"
        }
    }

    var endpoint: String {
        switch self {
        case .jellyfin: "auth/jellyfin"
        case .local: "auth/local"
        }
    }
}
