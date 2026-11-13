//
//  SeerDownloadDetailsView.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 13.11.26.
//

import SwiftUI

/// Detailed per-download progress, shown when tapping the processing chip.
struct SeerDownloadDetailsView: View {
    let progress: SeerDownloadProgress?

    var body: some View {
        Group {
            if let progress {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(progress.downloads) { download in
                            SeerDownloadRow(download: download)
                        }
                    }
                    .padding()
                }
                .scrollBounceBehavior(.basedOnSize)
            } else {
                ContentUnavailableView(
                    "Waiting for Download",
                    systemImage: "arrow.down.circle.dotted",
                    description: Text("The request was approved. The download will appear here once it starts.")
                )
            }
        }
        #if !os(tvOS)
        .frame(minWidth: 320, idealWidth: 420, maxWidth: 520)
        #endif
    }
}
