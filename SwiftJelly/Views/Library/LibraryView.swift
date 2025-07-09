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
        GridItem(.adaptive(minimum: defaultSize), spacing: 16)
    ]
    
    /// Default size for library cards
    static var defaultSize: CGFloat {
        #if os(macOS)
        260
        #else
        240
        #endif
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                }

                if !libraries.isEmpty && !isLoading {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(libraries, id: \.id) { library in
                            NavigationLink {
                                LibraryItemsView(library: library)
                            } label: {
                                LibraryCard(library: library)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .scenePadding(.horizontal)
                }
            }
            .navigationTitle("Libraries")
            .toolbarTitleDisplayMode(.inlineLarge)
            .task {
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
            libraries = try await JFAPI.shared.loadLibraries()
        } catch {
            print("Error loading libraries: \(error.localizedDescription)")
        }

        isLoading = false
    }
}
