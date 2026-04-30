//
//  SettingsView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import SwiftMediaViewer

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @AppStorage("showAppIconPicker") private var showAppIconPicker = false
    @State private var easterEggTapCount = 0

    var body: some View {
        SettingsSplitView {
            NavigationStack {
                form
            }
        } infoPanel: {
            Image("AppLogo")
                .resizable()
                .frame(width: 450, height: 450)
                .shadow(radius: 12)
        }
    }

    var form: some View {
        Form {
            NavigationLink {
                ServerList()
            } label: {
                Label("Servers", systemImage: "server.rack")
            }
            
            if showAppIconPicker {
                SeerrSettingsView()
            }

            Section("Playback") {
                PlaybackOptions()
                    .foregroundStyle(.primary)
            }

            Section("Appearance") {
                ViewOptions()
                    .foregroundStyle(.primary)
            }
            
            #if os(iOS) || os(tvOS) || os(visionOS)
            if showAppIconPicker {
                Section {
                    NavigationLink {
                        AppIconPicker()
                    } label: {
                        Label("App Icon", systemImage: "app.dashed")
                    }
                }
            }
            #endif

            Section("Images") {
                CacheManagerView()
            }

        }
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: 44)
                .contentShape(Rectangle())
                .onTapGesture {
                    easterEggTapCount += 1
                    if easterEggTapCount >= 7 {
                        showAppIconPicker = true
                        easterEggTapCount = 0
                    }
                }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .platformNavigationToolbar(titleDisplayMode: .inline)
        #if os(iOS)
        .toolbar {
            if horizontalSizeClass == .compact {
                Button(role: .close) { dismiss() }
            }
        }
        .contentMargins(.top, 10)
        #endif
    }
}


#Preview {
    SettingsView()
}
