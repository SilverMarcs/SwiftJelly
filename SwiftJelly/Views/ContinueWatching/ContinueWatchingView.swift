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

    private let api = JFAPI.shared

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            if !resumeItems.isEmpty && !isLoading {
                LazyHStack(spacing: 16) {
                    ForEach(resumeItems, id: \ .id) { item in
                        PlayableCard(item: item)
                    }
                }
                .padding(.horizontal)
                
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("No items to continue watching")
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
        .task {
            await loadResumeItems()
        }
    }

    private func loadResumeItems() async {
        isLoading = true

        do {
            resumeItems = try await api.loadResumeItems()
        } catch {
            print("Error loading resume items: \(error.localizedDescription)")
        }

        isLoading = false
    }
}
