//
//  ProgressBarOverlay.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import SwiftUI

struct ProgressBarOverlay: View {
    let title: String
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                .frame(height: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))
        }
        .padding(8)
    }
}
