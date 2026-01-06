//
//  TrendingInLibraryView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 14/12/2025.
//

import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct TrendingInLibraryView: View {
    @Bindable var viewModel: TrendingInLibraryViewModel
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach($viewModel.items, id: \.id) { item in
                    Group {
                    #if !os(tvOS)
                    MediaNavigationLink(item: item.wrappedValue) {
                        hero(item: item)
                    }
                    #else
                    hero(item: item)
                    .frame(height: 1080 * 0.75)
                    .padding(40)
                    .background {
                        if let url = ImageURLProvider.imageURL(for: item.wrappedValue, type: .backdrop) {
                            CachedAsyncImage(url: url, targetSize: 2000)
                                .scaledToFill()
                                .overlay {
                                    Rectangle()
                                        .fill(.regularMaterial)
                                        .mask {
                                            LinearGradient(
                                                stops: [
                                                    .init(color: .white, location: 0),
                                                    .init(color: .white.opacity(0.7), location: 0.5),
                                                    .init(color: .white.opacity(0), location: 1)
                                                ],
                                                startPoint: .bottomLeading, endPoint: .topTrailing
                                            )
                                        }
                                }
                        }
                    }
                    #endif
                    }
                    .id(item.wrappedValue.id)
                    .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $viewModel.scrolledID, anchor: .center)
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        #if os(tvOS)
        .ignoresSafeArea()
        .contentMargins(.horizontal, 1, for: .scrollContent) // peek tiny bit of next card for scroll to work
        #endif
        .onChange(of: viewModel.items) { _, newItems in
            // Start at 2nd element (index 1) when items load
            if newItems.count >= 2 {
                viewModel.scrolledID = newItems[1].id
            }
        }
        #if !os(tvOS)
        .overlay {
            // Navigation chevrons
            if viewModel.items.count > 1 {
                HStack {
                    Button {
                        withAnimation {
                            viewModel.scrollToPrevious()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(viewModel.currentIndex <= 0)
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            viewModel.scrollToNext()
                        }
                    } label: {
                        Image(systemName: "chevron.right")
    
                    }
                    .disabled(viewModel.currentIndex >= viewModel.items.count - 1)
                }
                .buttonBorderShape(.circle)
                .buttonStyle(.glass)
                #if os(macOS)
                .controlSize(.large)
                #endif
                .padding(.horizontal, 16)
            }
        }
        #endif
    }
    
    @ViewBuilder
    private func hero(item: Binding<BaseItemDto>) -> some View {
        switch item.wrappedValue.type {
        case .movie:
            MovieHeroView(movie: item)
        case .series:
            ShowHeroView(show: item)
        default:
            EmptyView()
        }
    }
}
