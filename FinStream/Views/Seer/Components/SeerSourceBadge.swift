//
//  SeerSourceBadge.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI

struct SeerSourceBadge: View {
    var body: some View {
        Label("Seer", systemImage: "sparkle.magnifyingglass")
            .labelStyle(.iconOnly)
            .font(.caption)
            .bold()
            .padding(8)
            .glassEffect(in: .circle)
            .padding(8)
    }
}
