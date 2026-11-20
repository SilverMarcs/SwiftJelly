//
//  PlatformNavigationToolbar.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 13/12/2025.
//

import SwiftUI

private struct PlatformNavigationToolbarModifier: ViewModifier {
    var titleDisplayMode: ToolbarTitleDisplayMode // no-op on tvOS
    
    func body(content: Content) -> some View {
        #if os(tvOS)
        content
            .toolbar(.hidden, for: .navigationBar)
        #else
        content
            .toolbarTitleDisplayMode(titleDisplayMode)
        #endif
    }
}

extension View {
    #if os(tvOS)
    func platformNavigationToolbar(titleDisplayMode: ToolbarTitleDisplayMode = .automatic) -> some View {
        modifier(PlatformNavigationToolbarModifier(titleDisplayMode: .automatic))
    }
    #else
    func platformNavigationToolbar(titleDisplayMode: ToolbarTitleDisplayMode = .inlineLarge) -> some View {
        modifier(PlatformNavigationToolbarModifier(titleDisplayMode: titleDisplayMode))
    }
    #endif
}

/// Unified title + single trailing toolbar item that actually renders on tvOS.
///
/// On iOS/macOS: maps to `navigationTitle` + `.toolbar { ToolbarItem(.primaryAction) }`.
/// On tvOS: hides the system nav bar and prepends a header row above `content`,
/// since the system toolbar is invisible there.
private struct PlatformTopBarModifier<Trailing: View>: ViewModifier {
    let title: String
    let titleDisplayMode: ToolbarTitleDisplayMode
    let trailing: Trailing

    #if os(iOS)
    @Environment(\.profileToolbarSettingsAction) private var profileToolbarSettingsAction
    @Environment(\.isPresented) private var isPresented
    #endif

    func body(content: Content) -> some View {
        #if os(tvOS)
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                trailing
            }
            .padding(.vertical, 24)
            .focusSection()
            content
        }
        .ignoresSafeArea(edges: [.top])
        .toolbar(.hidden, for: .navigationBar)
        #else
        content
            .navigationTitle(title)
            .toolbarTitleDisplayMode(titleDisplayMode)
            .toolbar {
                ToolbarItem(placement: .primaryAction) { trailing }
                #if os(iOS)
                // Declared after `trailing` so the profile menu sits at the trailing edge.
                // Only tab root screens show it, not screens pushed onto them.
                ProfileToolbarItem(showSettings: isPresented ? nil : profileToolbarSettingsAction)
                #endif
            }
        #endif
    }
}

extension View {
    #if os(tvOS)
    func platformTopBar<Trailing: View>(
        _ title: String,
        titleDisplayMode: ToolbarTitleDisplayMode = .automatic,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) -> some View {
        modifier(PlatformTopBarModifier(
            title: title,
            titleDisplayMode: .automatic,
            trailing: trailing()
        ))
    }
    #else
    func platformTopBar<Trailing: View>(
        _ title: String,
        titleDisplayMode: ToolbarTitleDisplayMode = .inlineLarge,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) -> some View {
        modifier(PlatformTopBarModifier(
            title: title,
            titleDisplayMode: titleDisplayMode,
            trailing: trailing()
        ))
    }
    #endif
}
