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
#else
        content
            .clipShape(.rect(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.background.quinary, lineWidth: 1)
            }
#endif
    }
}

extension View {
    func cardBorder(cornerRadius: CGFloat = 10) -> some View {
        modifier(CardBorderModifier(cornerRadius: cornerRadius))
    }
}

