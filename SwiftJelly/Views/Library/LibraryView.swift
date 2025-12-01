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

    #if os(tvOS)
    private let columns = [
        GridItem(.adaptive(minimum: 400), spacing: 48)
    ]
    private let gridSpacing: CGFloat = 48
    #else
    private let columns = [
        GridItem(.adaptive(minimum: 250), spacing: 16)
    ]
    private let gridSpacing: CGFloat = 16
    #endif

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: gridSpacing) {
                    ForEach(libraries, id: \.id) { library in
                        NavigationLink {
                            FilteredMediaView(filter: .library(library))
                        } label: {
                            #if os(tvOS)
                            LibraryCardTV(library: library)
                            #else
                            LandscapeImageView(item: library)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            #endif
                        }
                        #if os(tvOS)
                        .buttonStyle(.card)
                        #else
                        .buttonStyle(.plain)
                        #endif
                    }
                }
                .scenePadding(.horizontal)
                #if os(tvOS)
                .padding(.top, 20)
                #endif
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
            #if !os(tvOS)
            .refreshable {
                await loadLibraries()
            }
            #endif
            #if !os(macOS) && !os(tvOS)
            .toolbar {
                SettingsToolbar()
            }
            #endif
        }
    }

    private func loadLibraries() async {
        do {
            libraries = try await JFAPI.loadLibraries()
        } catch {
            print("Error loading Library: \(error.localizedDescription)")
        }
    }
}

#if os(tvOS)
private struct LibraryCardTV: View {
    let library: BaseItemDto
    
    var body: some View {
        LandscapeImageView(item: library)
            .aspectRatio(16/9, contentMode: .fill)
            .overlay {
                ZStack {
                    LinearGradient(
                        colors: [.black.opacity(0.7), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    
                    VStack {
                        Spacer()
                        Text(library.name ?? "Library")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                            .padding()
                    }
                }
            }
    }
}
#endif
