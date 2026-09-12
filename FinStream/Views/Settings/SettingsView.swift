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
            NavigationLink(value: SettingsRoute.serverList) {
                Label("Servers", systemImage: "server.rack")
            }

            #if !os(tvOS)
            NavigationLink(value: SettingsRoute.pairDevice) {
                Label("Pair a Device", systemImage: "bolt.horizontal.circle")
            }
            #endif

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
                    NavigationLink(value: SettingsRoute.appIcon) {
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
        .navigationDestination(for: SettingsRoute.self) { route in
            switch route {
            case .serverList:
                ServerList()
            #if !os(tvOS)
            case .pairDevice:
                PairDeviceView()
            #endif
            #if !os(macOS)
            case .appIcon:
                AppIconPicker()
            #endif
            }
        }
        .platformTopBar("Settings", titleDisplayMode: .inline)
        #if os(iOS)
        .contentMargins(.top, 10)
        #endif
    }
}


/// Navigation values for the settings screen, pushed onto the enclosing
/// `NavigationStack` via `NavigationLink(value:)`. Cases are conditional to
/// match where each row (and its destination view) is available per platform.
enum SettingsRoute: Hashable {
    case serverList
    #if !os(tvOS)
    case pairDevice
    #endif
    #if !os(macOS)
    case appIcon
    #endif
}

#Preview {
    SettingsView()
}
