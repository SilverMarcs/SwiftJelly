//
//  ServerGroup.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 29.07.26.
//

import Foundation

/// A Jellyfin host and the profiles (user logins) saved against it.
///
/// Each `Server` entry is really a *profile*: a single user login. Several
/// entries can share the same `url` — that's one physical server with multiple
/// profiles. `ServerGroup` collapses those entries so the UI can present
/// "Profiles & Servers" consistently.
struct ServerGroup: Identifiable {
    let id: String
    let name: String
    let url: URL
    let profiles: [Server]
}

extension DataManager {
    /// Saved profiles grouped by their Jellyfin host, preserving the order each
    /// host first appears in `servers`.
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
