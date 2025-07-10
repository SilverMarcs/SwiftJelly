//
//  SettingsView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import Kingfisher

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataManager = DataManager.shared
    @State private var showingServerSettings = false
    @State private var deleteAlertPresented = false
    @State private var cacheSize: String = "Calculating..."

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
                    LabeledContent {
                        Button(role: .destructive) {
                            deleteAlertPresented = true
                        } label: {
                            Text("Delete")
                        }
                        .tint(.red)
                        .buttonStyle(.borderedProminent)
                    } label: {
                        Label("Image Cache (\(cacheSize))", systemImage: "trash")
                    }
                    .alert("Clear Image Cache", isPresented: $deleteAlertPresented) {
                        Button("Clear", role: .destructive) {
                            ImageCache.default.clearCache()
                            calculateCacheSize()
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This will clear all cached images, freeing up storage space.")
                    }
                }
            }
            .scrollDisabled(true)
            .task {
                calculateCacheSize()
            }
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
    
    private func calculateCacheSize() {
        ImageCache.default.calculateDiskStorageSize { result in
            Task { @MainActor in
                switch result {
                case .success(let size):
                    self.cacheSize = String(format: "%.2f MB", Double(size) / 1024 / 1024)
                case .failure:
                    self.cacheSize = "Unknown"
                }
            }
        }
    }
}
