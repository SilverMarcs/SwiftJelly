//
//  GenreCardView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 14/12/2025.
//

import SwiftUI

struct GenreCardView: View {
    let name: String

    var body: some View {
        let baseHue = baseHue(for: name)
        let baseColor = baseColor(forHue: baseHue)
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(baseColor.gradient)
            .overlay {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .foregroundStyle(baseColor)
                    .brightness(1.25)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(12)
            }
            .frame(width: itemWidth, height: itemWidth * 0.35)
            .cardBorder()
            #if os(tvOS)
            .hoverEffect(.highlight)
            #endif
    }
    
    private var itemWidth: CGFloat {
        #if os(tvOS)
        250
        #elseif os(iOS)
        125
        #else
        150
        #endif
    }

    private func baseHue(for name: String) -> Double {
        let raw = stableHash64(name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        return Double(raw % 360) / 360.0
    }

    private func baseColor(forHue hue: Double) -> Color {
        // Shift hues away from the muddy brown/orange range (25-65 degrees)
        let adjustedHue: Double
        if hue > 0.07 && hue < 0.18 { // ~25-65 degrees
            // Push towards either red or yellow-green
            adjustedHue = hue < 0.125 ? hue - 0.07 : hue + 0.10
        } else {
            adjustedHue = hue
        }
        
        return Color(hue: adjustedHue, saturation: 0.82, brightness: 0.45)
    }

    private func stableHash64(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222326
        let prime: UInt64 = 0x100000001b3
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= prime
        }
        return hash
    }
}
