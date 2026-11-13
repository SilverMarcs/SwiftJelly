//
//  SeerProcessingChip.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 13.11.26.
//

import SwiftUI

/// A capsule showing overall download progress (e.g. "Processing S1") that reveals per-download details when tapped.
struct SeerProcessingChip: View {
    let progress: SeerDownloadProgress?

    @State private var isShowingDetails = false

    var body: some View {
        Button {
            isShowingDetails = true
        } label: {
            HStack(spacing: 8) {
                Text(progress?.title ?? String(localized: "Processing"))
                    .bold()
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
            }
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background {
                SeerProgressFill(fractionCompleted: progress?.fractionCompleted ?? 0, tint: .indigo)
                    .background(.indigo.opacity(0.35))
            }
            .clipShape(.capsule)
            .overlay {
                Capsule().strokeBorder(.indigo.opacity(0.9), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityValue(Text((progress?.fractionCompleted ?? 0), format: .percent.precision(.fractionLength(0))))
        #if os(tvOS)
        .sheet(isPresented: $isShowingDetails) {
            SeerDownloadDetailsView(progress: progress)
        }
        #else
        .popover(isPresented: $isShowingDetails) {
            SeerDownloadDetailsView(progress: progress)
                .presentationCompactAdaptation(.popover)
        }
        #endif
    }
}
