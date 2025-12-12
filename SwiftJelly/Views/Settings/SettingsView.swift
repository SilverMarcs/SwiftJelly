//
//  SettingsView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import SwiftMediaViewer

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Server") {
                NavigationLink {
                    ServerList()
                } label: {
                    Label("Servers", systemImage: "server.rack")
                }
            }

            Section("Images") {
                CacheManagerView()
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .toolbarTitleDisplayMode(.inline)
        #if os(tvOS)
        .toolbar(.hidden, for: .navigationBar)
//        .frame(maxWidth: 800)
        #endif
        #if os(iOS)
        .toolbar {
            Button("Close", systemImage: "xmark", role: .close) {
                dismiss()
            }
        }
        #endif
    }
}
