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
            VStack(alignment: .leading, spacing: 16) {
                Label {
                    Text(missingSeasonsText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "rectangle.stack.badge.plus")
                        .foregroundStyle(.tint)
                }

                FlowLayout(spacing: 8) {
                    ForEach(model.requestableSeasons) { season in
                        SeerMissingSeasonChip(season: season)
                    }
                }

                Button {
                    Task { await model.beginRequest() }
                } label: {
                    Group {
                        if model.isRequesting {
                            ProgressView()
                        } else {
                            Label("Request Missing Seasons", systemImage: "plus")
                        }
                    }
                    .bold()
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                #if os(tvOS)
                .controlSize(.regular)
                #else
                .controlSize(.large)
                #endif
                .disabled(model.isRequesting)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(in: .rect(cornerRadius: 24))
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
        return count == 1 ? "1 season isn't in your library yet" : "\(count) seasons aren't in your library yet"
    }
}
