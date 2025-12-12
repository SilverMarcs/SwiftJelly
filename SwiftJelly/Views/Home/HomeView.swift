//
//  HomeView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import JellyfinAPI

struct HomeView: View {
    @Environment(\.scenePhase) var scenePhase
    
    @State private var continueWatchingItems: [BaseItemDto] = []
    @State private var latestMovies: [BaseItemDto] = []
    @State private var latestShows: [BaseItemDto] = []
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: verticalSpacing) {
                ContinueWatchingView(items: continueWatchingItems)
                    .environment(\.refresh, refreshContinueWatching)
                
                RecentlyAddedView(items: latestMovies, header: "Recently Added Movies")

                RecentlyAddedView(items: latestShows, header: "Recently Added Shows")
            }
            .scenePadding(.bottom)
        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .overlay {
            if isLoading {
                UniversalProgressView()
            }
        }
        .task(id: scenePhase) {
            if scenePhase == .active {
                await loadAll()
            }
        }
        .navigationTitle("Continue Watching")
        #if os(tvOS)
        .toolbar(.hidden, for: .navigationBar)
        #else
        .toolbarTitleDisplayMode(.inlineLarge)
        .refreshable {
            await loadAll()
        }
        .toolbar {
            #if os(macOS)
            ToolbarItem {
                Button {
                    Task {
                        await loadAll()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r")
            }
            #else
            SettingsToolbar()
            #endif
        }
        #endif
    }

    private func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let continueWatching = JFAPI.loadContinueWatchingSmart()
            async let allItems = JFAPI.loadLatestMediaInLibrary(limit: 10)
            
            continueWatchingItems = try await continueWatching
            let items = try await allItems
            latestMovies = Array(items.filter { $0.type == .movie })
            latestShows = Array(items.filter { $0.type == .series })
        } catch {
            print("Error loading Home items: \(error)")
        }
    }

    private func refreshContinueWatching() async {
        do {
            let items = try await JFAPI.loadContinueWatchingSmart()
            
            withAnimation {
                continueWatchingItems = items
            }
        } catch {
            print("Error loading Continue Watching: \(error.localizedDescription)")
        }
    }
    
    private var verticalSpacing: CGFloat {
        #if os(tvOS)
        48
        #else
        24
        #endif
    }
}
