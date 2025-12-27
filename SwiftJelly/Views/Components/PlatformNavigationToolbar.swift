//
//  PlatformNavigationToolbar.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 13/12/2025.
//

import SwiftUI

private struct PlatformNavigationToolbarModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(tvOS)
        content
            .toolbar(.hidden, for: .navigationBar)
        #else
        content
            .toolbarTitleDisplayMode(.inlineLarge)
        #endif
    }
}

extension View {
    func platformNavigationToolbar() -> some View {
        modifier(PlatformNavigationToolbarModifier())
    }
}

