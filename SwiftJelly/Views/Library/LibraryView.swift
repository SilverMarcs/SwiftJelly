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

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: columnMinimumWidth), spacing: columnSpacing)]
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: gridSpacing) {
                ForEach(libraries, id: \.id) { library in
                    NavigationLink(value: FilteredMediaViewNavItem(item: library)) {
                        LandscapeImageView(item: library)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    #if os(tvOS)
                    .buttonStyle(.card)
                    #else
                    .buttonStyle(.plain)
                    #endif
                }
            }
            .scenePadding(.horizontal)
        }
        .overlay {
            if isLoading {
                UniversalProgressView()
            }
        }
        #if os(tvOS)
        .toolbar(.hidden, for: .navigationBar)
        #else
        .navigationTitle("Libraries")
        .toolbarTitleDisplayMode(.inlineLarge)
        #endif
        .task {
            if libraries.isEmpty {
                isLoading = true
                await loadLibraries()
                isLoading = false
            }
        }
        .refreshable {
            await loadLibraries()
        }
        #if !os(macOS) && !os(tvOS)
        .toolbar {
            SettingsToolbar()
        }
        #endif
    }
    
    private func loadLibraries() async {
        do {
            libraries = try await JFAPI.loadLibraries()
        } catch {
            print("Error loading Library: \(error.localizedDescription)")
        }
    }

    private var columnMinimumWidth: CGFloat {
        #if os(tvOS)
        400
        #else
        250
        #endif
    }

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
