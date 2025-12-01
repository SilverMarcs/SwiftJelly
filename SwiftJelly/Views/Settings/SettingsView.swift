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
        #if os(tvOS)
        tvOSSettings
        #else
        standardSettings
        #endif
    }
    
    #if os(tvOS)
    private var tvOSSettings: some View {
        NavigationStack {
            List {
                NavigationLink {
                    ServerList()
                } label: {
                    Label("Servers", systemImage: "server.rack")
                }
                
                CacheManagerView()
            }
            .listStyle(.grouped)
            .navigationTitle("Settings")
        }
    }
    #endif
    
    private var standardSettings: some View {
        NavigationStack {
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
}
