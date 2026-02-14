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
    
    /// Applies a platform-adaptive button style:
    /// - `.borderless` on tvOS
    /// - `.plain` on other platforms
    func adaptiveCardButtonStyle() -> some View {
        #if os(tvOS)
        self.buttonStyle(.card)
        #else
        self.buttonStyle(.plain)
        #endif
    }
    
    /// Disables a View via:
    /// - `.opacity` on tvOS to keep the Button focusable
    /// - `.disabled` on other platforms
    func adaptiveDisabled(_ disabled: Bool) -> some View {
        #if os(tvOS)
        self.opacity(disabled ? 0.5 : 1.0)
        #else
        self.disabled(disabled)
        #endif
    }
}

