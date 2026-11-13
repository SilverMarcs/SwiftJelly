//
//  SeerRequestStatusBadge.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI

struct SeerRequestStatusBadge: View {
    let status: SeerRequestDisplayStatus
    var downloadProgress: SeerDownloadProgress?

    var body: some View {
        if status == .processing || status == .partiallyAvailable, let downloadProgress {
            badge(title: downloadProgress.title, tint: .indigo)
                .background {
                    SeerProgressFill(fractionCompleted: downloadProgress.fractionCompleted, tint: .indigo)
                        .background(.indigo.opacity(0.35))
                }
                .clipShape(.capsule)
                .accessibilityValue(Text(downloadProgress.fractionCompleted, format: .percent.precision(.fractionLength(0))))
        } else {
            badge(title: status.title, tint: status.tint)
                .background(status.tint.opacity(0.75), in: .capsule)
        }
    }

    private func badge(title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption2)
            .bold()
            .lineLimit(1)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .overlay {
                Capsule().strokeBorder(tint, lineWidth: 1)
            }
            .fixedSize()
    }
}
