//
//  HomeView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Continue Watching Section
                    ContinueWatchingView()

                    Spacer(minLength: 100)
                }
//                .padding(.top)
            }
            .navigationTitle("Home")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }
}
