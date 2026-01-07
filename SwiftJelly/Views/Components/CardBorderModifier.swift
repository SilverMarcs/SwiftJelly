//
//  CardBorderModifier.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 13/12/2025.
//

import SwiftUI

private struct CardBorderModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
#if os(tvOS)
        content
            .hoverEffect(.highlight)
#else
        content
            .clipShape(.rect(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.tertiary, lineWidth: 1)
            }
#endif
    }
}

extension View {
    // TODO: switch to 10 if blurry border
    func cardBorder(cornerRadius: CGFloat = 12) -> some View {
        modifier(CardBorderModifier(cornerRadius: cornerRadius))
    }
}
