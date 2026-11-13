//
//  SeerProfileRow.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI

struct SeerProfileRow: View {
    let profile: Server

    var body: some View {
        HStack(spacing: 12) {
            UserAvatarView(server: profile, size: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.username ?? "User")

                if let account = profile.seer, account.isAuthenticated {
                    Text("Connected as \(account.displayName ?? account.username)")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text("Not connected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
