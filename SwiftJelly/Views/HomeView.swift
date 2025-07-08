//
//  HomeView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import JellyfinAPI

struct HomeView: View {
    @State private var resumeItems: [BaseItemDto] = []
    @State private var nextUpItems: [BaseItemDto] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        ContinueWatchingView(items: resumeItems)
                        NextUpView(items: nextUpItems)
//                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("Home")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                #if !os(macOS)
                SettingsToolbar()
                #else
                // refresh button
                Button {
                    Task { loadAll }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                #endif
            }
            .refreshable {
                await loadAll()
            }
            .task {
                await loadAll()
            }
        }
    }

    private func loadAll() async {
        isLoading = true
        async let resume = JFAPI.shared.loadResumeItems()
        async let nextUp = JFAPI.shared.loadNextUpItems()
        do {
            let (resumeResult, nextUpResult) = try await (resume, nextUp)
            resumeItems = resumeResult
            nextUpItems = nextUpResult
        } catch {
            print(error.localizedDescription)
        }
        isLoading = false
    }
}
