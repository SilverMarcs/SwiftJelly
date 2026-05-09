//
//  LibraryView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import SwiftUI
import JellyfinAPI

struct LibraryView: View {
    @State private var libraries: [BaseItemDto] = []
    @State private var isLoading = false
    #if os(iOS)
    @State private var downloadManager = DownloadManager.shared
    #endif

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: columnMinimumWidth), spacing: columnSpacing)]
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: gridSpacing) {
                #if os(iOS)
                if !downloadManager.downloads.isEmpty {
                    downloadsLink
                }
                #endif

                ForEach(libraries, id: \.id) { library in
                    MediaNavigationLink(item: library) {
                        libraryCardShape {
                            LandscapeImageView(item: library) {
                                Text(library.name ?? "")
                                    .font(.title)
                                    .bold()
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .background(.background.secondary)
                    }
                    .cardBorder()
                }

                #if os(iOS)
                if downloadManager.downloads.isEmpty {
                    downloadsLink
                }
                #endif
            }
            .scenePadding(.horizontal)
        }
        .overlay {
            if isLoading && libraries.isEmpty {
                UniversalProgressView()
            }
        }
        .navigationTitle("Libraries")
        .platformNavigationToolbar()
        #if !os(macOS)
        .toolbar {
            ToolbarItem {
                NavigationLink {
                    SettingsView()
                } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        #endif
        .task {
            if libraries.isEmpty {
                isLoading = true
                await loadLibraries()
                isLoading = false
            }
        }
        .refreshToolbar {
            await loadLibraries()
        }
    }
    
    private func loadLibraries() async {
        do {
            let loaded = try await JFAPI.loadLibraries()
            withAnimation {
                libraries = loaded
            }
        } catch {
            print("Error loading Library: \(error.localizedDescription)")
        }
    }

    /// Forces a 16:9 sized container regardless of whether the inner content
    /// has intrinsic size. Without this, a card whose image is missing and
    /// whose placeholder is just text would collapse to the text's height.
    @ViewBuilder
    private func libraryCardShape<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        Color.clear
            .aspectRatio(16/9, contentMode: .fit)
            .overlay { content() }
            .frame(minWidth: columnMinimumWidth, maxWidth: .infinity)
    }

    #if os(iOS)
    private var downloadsLink: some View {
        NavigationLink {
            DownloadsView()
        } label: {
            libraryCardShape {
                DownloadsLibraryCard()
            }
        }
        .buttonStyle(.plain)
        .cardBorder()
    }
    #endif

    private var columnMinimumWidth: CGFloat {
        #if os(tvOS)
        500
        #else
        250
        #endif
    }
    
    private var columnMinimumHeight: CGFloat { columnMinimumWidth * 0.5625 } // 16:9 Aspect Ratio

    private var columnSpacing: CGFloat {
        #if os(tvOS)
        48
        #else
        16
        #endif
    }

    private var gridSpacing: CGFloat {
        #if os(tvOS)
        48
        #else
        16
        #endif
    }
}
