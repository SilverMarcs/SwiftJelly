//
//  BlurredBottomOverlayModifier.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 14/12/2025.
//

import SwiftUI

struct BlurredBottomOverlayModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(tvOS)
        content.overlay {
            Rectangle()
                .fill(.regularMaterial)
                .mask {
                    LinearGradient(
                        colors: [.black, .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                }
        }
        #else
        content.overlay {
            LinearGradient(
                colors: [.black.opacity(0.67), .clear],
                startPoint: .bottom,
                endPoint: .top
            )
        }
        #endif
    }
}

extension View {
    func blurredBottomOverlay() -> some View {
        modifier(BlurredBottomOverlayModifier())
    }
}
