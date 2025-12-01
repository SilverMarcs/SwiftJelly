//
//  SettingsToolbar.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 01/07/2025.
//

import SwiftUI

#if !os(tvOS)
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
                SettingsView()
                    .presentationDetents([.medium])
                    #if !os(macOS)
                    .navigationTransition(.zoom(sourceID: "settings-button", in: transition))
                    #endif
            }
        }
        #if !os(macOS)
        .matchedTransitionSource(id: "settings-button", in: transition)
        #endif
    }
}
#endif
