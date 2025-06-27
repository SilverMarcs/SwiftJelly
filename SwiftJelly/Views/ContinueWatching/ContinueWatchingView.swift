//
//  ContinueWatchingView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import VLCUI

struct ContinueWatchingView: View {
    @StateObject private var homeViewModel = HomeViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Continue Watching")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                if homeViewModel.isLoading {
                    ProgressView()
                }
            }
            .padding(.horizontal)

            if let error = homeViewModel.error {
                Text("Error: \(error)")
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }

            if !homeViewModel.resumeItems.isEmpty && !homeViewModel.isLoading {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(homeViewModel.resumeItems, id: \ .id) { item in
                            ContinueWatchingCard(item: item)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .task {
            await homeViewModel.loadResumeItems()
        }
        .refreshable {
            await homeViewModel.loadResumeItems()
        }
    }
}
