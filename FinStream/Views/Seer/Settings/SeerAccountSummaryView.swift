//
//  SeerAccountSummaryView.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI

struct SeerAccountSummaryView: View {
    let profile: Server
    let account: SeerAccount
    let onChange: () -> Void

    var body: some View {
        Form {
            Section("Account") {
                LabeledContent("Jellyfin Profile", value: profile.username ?? "User")
                LabeledContent("Signed in as", value: account.displayName ?? account.username)
                LabeledContent("Sign-in Method", value: account.authMethod.title)
            }

            Section {
                Button {
                    onChange()
                } label: {
                    Label("Change Account", systemImage: "arrow.triangle.2.circlepath")
                }

                Button(role: .destructive) {
                    SeerAPI.disconnect(profile: profile)
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } footer: {
                Text(account.url.absoluteString)
            }
        }
        .formStyle(.grouped)
        #if os(iOS)
        .contentMargins(.top, 10)
        #endif
    }
}
