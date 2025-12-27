//
//  View++.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 13/12/2025.
//

import SwiftUI

extension View {
    /// Applies a platform-adaptive button style:
    /// - `.borderless` on tvOS
    /// - `.plain` on other platforms
    func adaptiveButtonStyle() -> some View {
        #if os(tvOS)
        self.buttonStyle(.borderless)
        #else
        self.buttonStyle(.plain)
        #endif
    }
}
