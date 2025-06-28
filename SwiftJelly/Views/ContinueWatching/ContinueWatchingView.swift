//
//  ContinueWatchingView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import JellyfinAPI
import VLCUI

struct ContinueWatchingView: View {
    @State private var resumeItems: [BaseItemDto] = []
    @State private var isLoading = false

    private let apiService = JellyfinAPIService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Continue Watching")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                if isLoading {
                    ProgressView()
                }
            }
            .padding(.horizontal)

            if !resumeItems.isEmpty && !isLoading {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(resumeItems, id: \ .id) { item in
                            MediaPlaybackCard(item: item)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .task {
            await loadResumeItems()
        }
    }

    private func loadResumeItems() async {
        isLoading = true

        do {
            resumeItems = try await apiService.loadResumeItems()
        } catch {
            print("Error loading resume items: \(error.localizedDescription)")
        }

        isLoading = false
    }
}
