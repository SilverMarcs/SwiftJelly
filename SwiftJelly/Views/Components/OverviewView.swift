//
//  OverviewView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 23/09/2025.
//

import SwiftUI
import JellyfinAPI

struct OverviewView: View {
    let item: BaseItemDto
    var compact: Bool = false

    @State private var showFullOverview = false

    var body: some View {
        let overview = item.overview ?? item.taglines?.first
        let display = overview ?? "A placeholder description that occupies enough room to mimic the real overview while content is loading from the server."
        VStack(alignment: .leading, spacing: 12) {
            Text(display)
                #if os(tvOS)
                .font(.caption)
                #elseif os(iOS)
                .font(compact ? .subheadline : .callout)
                #else
                .font(.callout)
                #endif
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(2, reservesSpace: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .redacted(reason: overview == nil ? .placeholder : [])
                #if !os(tvOS)
                .overlay(alignment: .bottomTrailing) {
                    if let realOverview = overview {
                        Button {
                            showFullOverview = true
                        } label: {
                            Text("More")
                                .font(.caption)
                        }
                        .buttonStyle(.glass)
                        .sheet(isPresented: $showFullOverview) {
                            OverviewSheetView(
                                item: item,
                                overview: realOverview,
                                isPresented: $showFullOverview
                            )
                        }
                    }
                }
                #endif
        }
    }
}
