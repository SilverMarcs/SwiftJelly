//
//  MediaPlayerProgressBar.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 29/06/2025.
//

import SwiftUI

/// Reusable media player progress bar with time labels and seek slider
struct MediaPlayerProgressBar: View {
    let currentSeconds: Int
    let totalSeconds: Int
    let seekValue: Double
    let isSeeking: Bool
    let onSeekValueChanged: (Double) -> Void
    let onSeekingChanged: (Bool) -> Void
    
    var body: some View {
        HStack {
            Text(currentSeconds.formattedTime)
                .font(.caption)
                .foregroundColor(.white)
                .monospacedDigit()
            
            Slider(
                value: Binding(
                    get: { isSeeking ? seekValue : Double(currentSeconds) },
                    set: onSeekValueChanged
                ),
                in: 0...Double(totalSeconds),
                onEditingChanged: onSeekingChanged
            )
            
            Text(totalSeconds.formattedTime)
                .font(.caption)
                .foregroundColor(.white)
                .monospacedDigit()
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}
