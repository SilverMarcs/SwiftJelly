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
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(background(for: name))
            .overlay {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(12)
            }
            .frame(width: itemWidth * 1.5, height: itemWidth * 0.5)
            .cardBorder()
    }
    
    private var itemWidth: CGFloat {
        #if os(tvOS)
        200
        #elseif os(iOS)
        75
        #else
        100
        #endif
    }

    private func background(for name: String) -> LinearGradient {
        let raw = stableHash64(name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        let hue1 = Double(raw % 360) / 360.0
        let hue2 = Double((raw / 7) % 360) / 360.0
        let c1 = Color(hue: hue1, saturation: 0.78, brightness: 0.54)
        let c2 = Color(hue: hue2, saturation: 0.74, brightness: 0.44)
        return LinearGradient(
            colors: [
                c1.opacity(0.95),
                c2.opacity(0.90),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
