//
//  UniversalProgressView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI

struct UniversalProgressView: View {
#if os(tvOS)
    var body: some View {
        HStack(spacing: 15) {
            ProgressView()
                .controlSize(.large)
            
            Text("Loading")
                .opacity(0.5)
        }
        .padding()
        .glassEffect(in: .capsule)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
#else
    var body: some View {
        ProgressView()
            .controlSize(.large)
            .padding()
            .glassEffect(in: .circle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
#endif
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
