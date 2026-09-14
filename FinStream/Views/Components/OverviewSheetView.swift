//
//  OverviewSheetView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 13/04/2026.
//

import SwiftUI

struct OverviewSheetView: View {
    let overview: String

    var body: some View {
        ScrollView {
            Text(overview)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                #if !os(tvOS)
                .padding()
                #endif
        }
        #if os(tvOS)
        .contentMargins(48, for: .scrollContent)
        .frame(width: 1000, height: 480)
        .presentationSizing(.fitted)
        #else
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        #endif
    }
}
