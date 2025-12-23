//
//  SettingsView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import SwiftMediaViewer

struct SettingsView: View {
    #if !os(tvOS)
    @Environment(\.dismiss) private var dismiss
    #endif

    var body: some View {
        standardSettings
    }
    
    private var standardSettings: some View {
        Form {
            Section("Server") {
                NavigationLink(value: ServerListNavigationItem()) {
                    Label("Servers", systemImage: "server.rack")
                }
            }

            Section("Images") {
                CacheManagerView()
            }
        }
        #if !os(tvOS)
        .scrollDisabled(true)
        #endif
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .toolbarTitleDisplayMode(.inline)
        #if !os(macOS) && !os(tvOS)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        
                }
            }
        }
        #endif
    }
}
