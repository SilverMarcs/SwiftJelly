//
//  SeerProgressFill.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 13.11.26.
//

import SwiftUI

/// A leading-aligned fill covering `fractionCompleted` of the available width.
struct SeerProgressFill: View {
    let fractionCompleted: Double
    let tint: Color

    var body: some View {
        Rectangle()
            .fill(tint)
            .scaleEffect(x: min(max(fractionCompleted, 0), 1), y: 1, anchor: .leading)
            .animation(.smooth, value: fractionCompleted)
    }
}
