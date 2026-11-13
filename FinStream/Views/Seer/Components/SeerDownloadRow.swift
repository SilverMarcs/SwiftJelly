//
//  SeerDownloadRow.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 13.11.26.
//

import SwiftUI

struct SeerDownloadRow: View {
    let download: SeerDownload

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(download.title)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)

            SeerDownloadProgressBar(fractionCompleted: download.fractionCompleted, tint: download.state.tint)

            HStack {
                Text(download.state.title)
                    .font(.subheadline)
                    .bold()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(download.state.tint.opacity(0.6), in: .capsule)

                Spacer(minLength: 0)

                if let estimatedCompletion = download.estimatedCompletion, estimatedCompletion > .now {
                    Text("Estimated \(estimatedCompletion, format: .relative(presentation: .named))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
