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
//            .glassEffect(in: .circle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
