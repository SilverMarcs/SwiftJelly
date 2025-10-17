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

    private let columns = [
        GridItem(.adaptive(minimum: 250), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(libraries, id: \.id) { library in
                        NavigationLink {
                            FilteredMediaView(filter: .library(library))
                        } label: {
                            LandscapeImageView(item: library)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .scenePadding(.horizontal)
            }
            .overlay {
                if isLoading {
                    UniversalProgressView()
                }
            }
            .navigationTitle("Libraries")
            .toolbarTitleDisplayMode(.inlineLarge)
            .task {
                if libraries.isEmpty {
                    await loadLibraries()
                }
            }
            .refreshable {
                await loadLibraries()
            }
            #if !os(macOS)
            .toolbar {
                SettingsToolbar()
            }
            #endif
        }
    }

    private func loadLibraries() async {
        isLoading = true

        do {
            libraries = try await JFAPI.loadLibraries()
        } catch {
            print("Error loading Library: \(error.localizedDescription)")
        }

        isLoading = false
    }
}
