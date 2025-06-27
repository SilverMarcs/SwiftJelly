//
//  HomeView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack {
            Text("Home")
                .font(.largeTitle)
                .foregroundStyle(.primary)
            Text("This is the Home tab.")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
