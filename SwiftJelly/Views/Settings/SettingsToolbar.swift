//
//  SettingsToolbar.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 01/07/2025.
//

import SwiftUI

struct SettingsModifier: ViewModifier {
    @State private var isPresented: Bool = false
    @Namespace private var transition

    func body(content: Content) -> some View {
        #if os(macOS)
        content
        #else
        content
            .toolbar {
                ToolbarItem {
                    Button {
                        isPresented = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
                #if !os(tvOS)
                .matchedTransitionSource(id: "settings-button", in: transition)
                #endif
            }
            .sheet(isPresented: $isPresented) {
                NavigationStack {
                    SettingsView()
                }
                .navigationTransition(.zoom(sourceID: "settings-button", in: transition))
            }
        #endif
    }
}

extension View {
    func settingsSheet() -> some View {
        modifier(SettingsModifier())
    }
}
