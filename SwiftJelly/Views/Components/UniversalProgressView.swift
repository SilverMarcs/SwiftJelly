//
//  UniversalProgressView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI

struct UniversalProgressView: View {
    var body: some View {
        ProgressView()
            .controlSize(.large)
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
//            .glassEffect(in: RoundedRectangle(cornerRadius: 14))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

//struct UniversalProgressView: View {
//    var body: some View {
//        ZStack {
//            // Semi-transparent dark background
//            Rectangle()
//                .fill(.background)
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//            
//            // Progress indicator
//            ProgressView()
//                .controlSize(.large)        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .listRowSeparator(.hidden)
//    }
//}
//
