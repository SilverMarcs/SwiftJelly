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
            .glassEffect(in: .rect(cornerRadius: 24))
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
