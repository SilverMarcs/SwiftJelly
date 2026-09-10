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
    @AppStorage(HomeContentSettings.useModularHomeTrendingKey)
    private var useModularHomeTrending = false
    @State private var easterEggTapCount = 0

    var body: some View {
        SettingsSplitView {
            #if os(macOS)
            NavigationStack {
                form
            }
            #else
            form
            #endif
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

            Section("View Options") {
                ViewOptions()
                    .foregroundStyle(.primary)
            }

            if showAppIconPicker {
                Section {
                    Toggle("Use Modular Home Trending", isOn: $useModularHomeTrending)
                } footer: {
                    Text("Uses Modular Home trending for the Home hero and Top Shelf. Enabled automatically for LumiStream. Falls back to Seerr trending, then recently added titles.")
                }
            }

            #if !os(macOS)
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
        .platformTopBar("Settings", titleDisplayMode: .inline)
        #if os(iOS)
        .contentMargins(.top, 10)
        #endif
    }
}


#Preview {
    SettingsView()
}
