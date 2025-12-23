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
    @State private var dataManager = DataManager.shared
    
    @Namespace private var animation
    @State private var continueWatchingItems: [BaseItemDto] = []
    @State private var latestMovies: [BaseItemDto] = []
    @State private var latestShows: [BaseItemDto] = []
    @State private var isLoading = false

    #if os(tvOS)
    private let verticalSpacing: CGFloat = 48
    private let horizontalMargin: CGFloat = 48
    #else
    private let verticalSpacing: CGFloat = 24
    private let horizontalMargin: CGFloat = 15
    #endif

    var body: some View {
        Group {
            if dataManager.servers.isEmpty {
                ContentUnavailableView {
                    Label("No Server Found", systemImage: "server.rack")
                } description: {
                    Text("Please connect to a Jellyfin server to continue.")
                } actions: {
                    NavigationLink {
                        AddServerView()
                    } label: {
                        Text("Add Server")
                    }
                    #if os(tvOS)
                    .buttonStyle(.borderedProminent)
                    #else
                    .buttonStyle(.borderedProminent)
                    #endif
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: verticalSpacing) {
                        ContinueWatchingView(items: continueWatchingItems)
                            .environment(\.refresh, refreshContinueWatching)
                        
                        RecentlyAddedView(items: latestMovies, header: "Recently Added Movies")

                        RecentlyAddedView(items: latestShows, header: "Recently Added Shows")
                    }
                    .scenePadding(.bottom)
                    .contentMargins(.horizontal, horizontalMargin)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                #if os(tvOS)
                .overlay {
                    if isLoading {
                        UniversalProgressView()
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
                #else
                .refreshable {
                    await loadAll()
                }
                .navigationTitle("Continue Watching")
                .toolbar {
                    if isLoading {
                        ToolbarItem {
                            ProgressView()
                            #if os(macOS)
                                .controlSize(.small)
                                .padding(10)
                            #endif
                        }
                    }
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
        }
        .task(id: scenePhase) {
            if scenePhase == .active && !dataManager.servers.isEmpty {
                await loadAll()
            }
        }
        .task(id: dataManager.servers.count) {
            if !dataManager.servers.isEmpty {
                await loadAll()
            }
        }
    }

    private func loadAll() async {
        isLoading = true
        defer { isLoading = false}
        do {
            async let continueWatching = JFAPI.loadContinueWatchingSmart()
            async let movies = JFAPI.loadLatestMediaInLibrary(limit: 20, itemTypes: [.movie])
            async let shows = JFAPI.loadLatestMediaInLibrary(limit: 20, itemTypes: [.series])

            continueWatchingItems = try await continueWatching
            latestMovies = try await movies
            latestShows = try await shows
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
}
