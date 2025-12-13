//
//  RefreshToolbar.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 13/12/2025.
//

import SwiftUI

private struct RefreshToolbarModifier: ViewModifier {
    let action: () async -> Void

    func body(content: Content) -> some View {
        #if os(macOS)
        content
            .toolbar {
                ToolbarItem {
                    Button {
                        Task { await action() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .keyboardShortcut("r")
                }
            }
        #else
        content
        #endif
    }
}

extension View {
    func refreshToolbar(
        action: @escaping () async -> Void
    ) -> some View {
        modifier(RefreshToolbarModifier(action: action))
    }
}

