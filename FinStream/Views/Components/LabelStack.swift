//
//  LabelStack.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 13/12/2025.
//

import SwiftUI

/// A container that wraps content in a VStack on non-tvOS platforms,
/// tvOS requires not having a vstack below image labels for buttons/cards to avoid overlapping the text below it
struct LabelStack<Content: View>: View {
    let alignment: HorizontalAlignment
    let spacing: CGFloat?
    @ViewBuilder let content: () -> Content
    
    init(alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        #if os(tvOS)
        content()
        #else
        VStack(alignment: alignment, spacing: spacing) {
            content()
        }
        #endif
    }
}
