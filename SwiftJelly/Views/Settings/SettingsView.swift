//
//  SettingsView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import CachedAsyncImage

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingServerSettings = false
    @State private var deleteAlertPresented = false

    var body: some View {
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
                    Button {
                        deleteAlertPresented = true
                    } label: {
                        HStack {
                            Label {
                                Text("Clear Image Cache")
                                
                            } icon: {
                                Image(systemName: "trash")
                            }
                            
//                            Spacer()
//                            
//                            Text("{Cache Size}")
                        }
                        .contentShape(.rect)
                    }
                    #if os(macOS)
                    .buttonStyle(.plain)
                    #endif
                    .alert("Clear Image Cache", isPresented: $deleteAlertPresented) {
                        Button("Clear", role: .destructive) {
                            Task {
                                await MemoryCache.shared.clearCache()
                                await DiskCache.shared.clearCache()
                            }
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This will clear all cached images, freeing up storage space.")
                    }
                }
            }
            .scrollDisabled(true)
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .toolbarTitleDisplayMode(.inline)
            #if !os(macOS)
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
