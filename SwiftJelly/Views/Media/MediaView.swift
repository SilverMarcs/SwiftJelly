//
//  MediaView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import SwiftUI
import JellyfinAPI

struct MediaView: View {
    @StateObject private var viewModel = MediaViewModel()
    @EnvironmentObject private var dataManager: DataManager
    
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                    
                    if let error = viewModel.error {
                        Text("Error: \(error)")
                            .foregroundStyle(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    if !viewModel.libraries.isEmpty && !viewModel.isLoading {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.libraries, id: \.id) { library in
                                NavigationLink(destination: LibraryItemsView(library: library)) {
                                    LibraryCard(library: library)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Media Libraries")
            .task {
                await viewModel.loadLibraries()
            }
        }
    }
}

#Preview {
    MediaView()
        .environmentObject(DataManager.shared)
}
