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
                    MediaNavigationLink(item: library) {
                        LandscapeImageView(item: library)
                            #if !os(tvOS)
                            .clipShape(.rect(cornerRadius: 12))
                            #endif
                    }
                }
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
