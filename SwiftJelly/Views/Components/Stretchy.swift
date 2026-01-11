//
//  Stretchy.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 29/09/2025.
//

import SwiftUI

extension View {
    func stretchy() -> some View {
        visualEffect { effect, geometry in
            let currentHeight = geometry.size.height
            let scrollOffset = geometry.frame(in: .scrollView).minY
            let positiveOffset = max(0, scrollOffset)

            let scaleFactor: CGFloat
            if currentHeight > .leastNonzeroMagnitude {
                scaleFactor = (currentHeight + positiveOffset) / currentHeight
            } else {
                scaleFactor = 1
            }

            let safeScale = scaleFactor.isFinite ? scaleFactor : 1

            return effect.scaleEffect(
                x: safeScale, y: safeScale,
                anchor: .bottom
            )
        }
    }
}
