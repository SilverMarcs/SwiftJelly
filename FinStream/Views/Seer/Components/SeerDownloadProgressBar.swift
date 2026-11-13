//
//  SeerDownloadProgressBar.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 13.11.26.
//

import SwiftUI

/// A capsule progress bar with the percentage centered on top, matching the Seer website.
struct SeerDownloadProgressBar: View {
    let fractionCompleted: Double
    var tint: Color = .indigo

    var body: some View {
        Text(fractionCompleted, format: .percent.precision(.fractionLength(0)))
            .font(.subheadline)
            .monospacedDigit()
            .foregroundStyle(.white)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background {
                SeerProgressFill(fractionCompleted: fractionCompleted, tint: tint)
                    .background(.white.opacity(0.12))
            }
            .clipShape(.capsule)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Download progress")
            .accessibilityValue(Text(fractionCompleted, format: .percent.precision(.fractionLength(0))))
    }
}
