//
//  ServerGroup.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 29.07.26.
//

import Foundation

/// Saved `Server` entries (one per user login) that share a host URL.
struct ServerGroup: Identifiable {
    let id: String
    let name: String
    let url: URL
    let profiles: [Server]
}

extension DataManager {
    /// Ordered by each host's first appearance in `servers`.
    var serverGroups: [ServerGroup] {
        var order: [String] = []
        var grouped: [String: [Server]] = [:]

        for server in servers {
            let key = server.url.absoluteString
            if grouped[key] == nil { order.append(key) }
            grouped[key, default: []].append(server)
        }

        return order.compactMap { key in
            guard let profiles = grouped[key], let first = profiles.first else { return nil }
            return ServerGroup(id: key, name: first.name, url: first.url, profiles: profiles)
        }
    }
}
