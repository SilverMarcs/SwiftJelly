//
//  SeerAccountView.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI

struct SeerAccountView: View {
    private var dataManager = DataManager.shared

    let profileID: String

    @State private var isEditing = false

    init(profileID: String) {
        self.profileID = profileID
    }

    private var profile: Server? {
        dataManager.servers.first { $0.id == profileID }
    }

    var body: some View {
        SettingsSplitView {
            content
        } infoPanel: {
            VStack(spacing: 20) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 200))
                    .foregroundStyle(.secondary)

                Text("Seer")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Seer")
        .platformNavigationToolbar(titleDisplayMode: .inline)
    }

    @ViewBuilder
    private var content: some View {
        if let profile {
            if let account = profile.seer, account.isAuthenticated, !isEditing {
                SeerAccountSummaryView(profile: profile, account: account) {
                    isEditing = true
                }
            } else {
                SeerLoginForm(model: SeerLoginViewModel(profile: profile, suggestedURL: suggestedURL(for: profile))) {
                    isEditing = false
                }
            }
        } else {
            ContentUnavailableView("Profile Removed", systemImage: "person.crop.circle.badge.xmark")
        }
    }

    private func suggestedURL(for profile: Server) -> URL? {
        dataManager.servers
            .filter { $0.url == profile.url }
            .compactMap(\.seer?.url)
            .first
    }
}
