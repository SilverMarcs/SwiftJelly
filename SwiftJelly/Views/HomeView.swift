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
                    
                    // Other sections can be added here
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Other Content")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        Text("More sections will be added here")
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.top)
            }
            .navigationTitle("Home")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }
}
