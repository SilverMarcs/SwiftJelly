//
//  SeerRequestMoreView.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI

struct SeerRequestMoreView: View {
    let model: SeerRequestViewModel

    var body: some View {
        SectionContainer {
            VStack(alignment: .leading, spacing: 12) {
                Text(missingSeasonsText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    Task { await model.beginRequest() }
                } label: {
                    Label("Request More", systemImage: "plus")
                        .font(.callout)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .foregroundStyle(.primary)
                #if os(tvOS)
                .controlSize(.regular)
                #else
                .controlSize(.large)
                #endif
                .disabled(model.isRequesting)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .scenePadding(.horizontal)
            #if os(tvOS)
            .focusSection()
            #endif
        } header: {
            Text("Missing Seasons")
        }
        .seerRequestPresentation(model)
    }

    private var missingSeasonsText: String {
        let count = model.requestableSeasons.count
        return count == 1 ? "1 season is not on your server yet" : "\(count) seasons are not on your server yet"
    }
}
