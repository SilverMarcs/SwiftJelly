//
//  MediaView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import SwiftUI
import JellyfinAPI

struct MediaView: View {
    @State private var libraries: [BaseItemDto] = []
    @State private var isLoading = false
    @EnvironmentObject private var dataManager: DataManager

    private let columns = [
        GridItem(.adaptive(minimum: 240), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView()
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
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Media Libraries")
            .toolbarTitleDisplayMode(.inlineLarge)
            .task {
                await loadLibraries()
            }
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

#Preview {
    MediaView()
        .environmentObject(DataManager.shared)
}
