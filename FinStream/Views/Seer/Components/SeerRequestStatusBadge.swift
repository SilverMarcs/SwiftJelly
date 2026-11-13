//
//  SeerRequestStatusBadge.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI

struct SeerRequestStatusBadge: View {
    let status: SeerRequestDisplayStatus

    var body: some View {
        Label(status.title, systemImage: status.systemImage)
            .font(.caption2)
            .bold()
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.tint.opacity(0.8), in: .capsule)
    }
}
