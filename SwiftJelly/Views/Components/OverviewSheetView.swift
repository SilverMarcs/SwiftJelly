//
//  OverviewSheetView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 13/04/2026.
//

import SwiftUI

struct OverviewSheetView: View {
    let title: String
    let overview: String
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(overview)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .close) {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
