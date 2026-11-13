//
//  SeerRequestButton.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI

struct SeerRequestButton: View {
    let model: SeerRequestViewModel

    var body: some View {
        Button {
            Task { await model.beginRequest() }
        } label: {
            HStack(spacing: 8) {
                if model.isRequesting || model.state == .loading {
                    ProgressView()
                        #if !os(tvOS)
                        .controlSize(.mini)
                        #endif
                } else {
                    Image(systemName: model.state.systemImage)
                }

                Text(model.state.title)
            }
            .font(.callout)
            .fontWeight(.semibold)
        }
        .adaptiveDisabled(!model.state.canRequest || model.isRequesting)
        .animation(.default, value: model.state)
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        #if os(tvOS)
        .controlSize(.regular)
        #else
        .tint(Color(.accent).secondary)
        .controlSize(.extraLarge)
        #endif
    }
}
