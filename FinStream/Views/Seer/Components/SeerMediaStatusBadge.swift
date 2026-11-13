//
//  SeerMediaStatusBadge.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI

struct SeerMediaStatusBadge: View {
    let status: SeerMediaStatus

    var body: some View {
        let state = SeerRequestState(status: status)
        if state != .requestable {
            Label(state.title, systemImage: state.systemImage)
                .font(.caption)
                .bold()
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .glassEffect(in: .capsule)
        }
    }
}
