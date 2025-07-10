//
//  FullScreenFrameModifier.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI

struct FullScreenFrameModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(minHeight: {
                #if os(iOS)
                return UIScreen.main.bounds.height/2
                #elseif os(macOS)
                return NSScreen.main?.frame.height ?? 600
                #else
                return 600
                #endif
            }())
    }
}

// Extension to make it easier to use
extension View {
    func fullScreenFrame() -> some View {
        modifier(FullScreenFrameModifier())
    }
}
