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
