//
//  HomeView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import JellyfinAPI

struct HomeView: View {
    @State private var continueWatchingItems: [BaseItemDto] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    ContinueWatchingView(items: continueWatchingItems)
                        .scenePadding(.horizontal)
                }
            }
            .navigationTitle("Home")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                #if !os(macOS)
                SettingsToolbar()
                #else
                Button {
                    Task { await loadAll() }
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
        do {
            let items = try await JFAPI.shared.loadContinueWatchingSmart()
            continueWatchingItems = items
        } catch {
            print(error.localizedDescription)
        }
        isLoading = false
    }
}
