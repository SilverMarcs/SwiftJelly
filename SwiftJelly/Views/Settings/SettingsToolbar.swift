//
//  SettingsToolbar.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 01/07/2025.
//

import SwiftUI

struct SettingsToolbar: ToolbarContent {
    @State var isPresented: Bool = false
    @Namespace private var transition
    
    var body: some ToolbarContent {
        ToolbarItem {
            Button {
                isPresented = true
            } label: {
                Label("Settings", systemImage: "gear")
            }
            .sheet(isPresented: $isPresented) {
                NavigationStack {
                    SettingsView()
                        .presentationDetents([.medium])
                }
            }
        }
        #if os(iOS)
        .matchedTransitionSource(id: "settings-button", in: transition)
        #endif
    }
}
