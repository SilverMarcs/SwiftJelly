//
//  RefreshToolbar.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 13/12/2025.
//

import SwiftUI

private struct RefreshToolbarModifier: ViewModifier {
    let action: () async -> Void
    @State private var isRefreshing = false

    func body(content: Content) -> some View {
        content
            .refreshable {
                await runRefresh()
            }
            #if os(macOS)
            .toolbar {
                ToolbarItem {
                    Button {
                        Task { await runRefresh() }
                    } label: {
                        if isRefreshing {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    }
                    .disabled(isRefreshing)
                    .keyboardShortcut("r")
                }
            }
            #endif
    }

    private func runRefresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        await action()
    }
}

extension View {
    func refreshToolbar(
        action: @escaping () async -> Void
    ) -> some View {
        modifier(RefreshToolbarModifier(action: action))
    }
}
