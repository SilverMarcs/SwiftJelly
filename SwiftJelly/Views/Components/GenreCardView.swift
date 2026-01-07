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
        let baseColor = color(for: name)
        
        Text(name)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .foregroundStyle(baseColor)
            .brightness(1.25)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .padding(.horizontal, padding)
            .padding(.vertical, padding - 2)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(baseColor.gradient)
                    .brightness(-0.25)
            }
            #if os(tvOS)
            .hoverEffect(.highlight)
            #endif
            .cardBorder()
    }

    private func color(for name: String) -> Color {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let raw = stableHash64(normalizedName)
        return Self.systemPalette[Int(raw % UInt64(Self.systemPalette.count))]
    }
    
    private var font: Font {
        #if os(tvOS)
        .subheadline
        #else
        .headline
        #endif
    }
    
    private var padding: CGFloat {
        #if os(tvOS)
        18
        #else
        12
        #endif
    }

    private static let systemPalette: [Color] = [
        .red,
        .orange,
        .yellow,
        .green,
        .mint,
        .teal,
        .cyan,
        .blue,
        .indigo,
        .purple,
        .pink,
        .brown
    ]

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
