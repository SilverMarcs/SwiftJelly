//
//  FeaturedView.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 11.02.26.
//

import SwiftUI
import SwiftMediaViewer
import JellyfinAPI

struct FeaturedView: View {
    let loadItemsAction: @Sendable () async throws -> [BaseItemDto]

    @State private var scrollOffset: CGFloat = 0
    @State private var item: BaseItemDto = BaseItemDto()
    @State private var itemsLoaded = false
    @State private var showDetailViewModel: ShowDetailViewModel? = nil
    @State var shouldFocus: Bool = true
    
    var body: some View {
        #if os(tvOS)
        tvOSView
        #else
        staticDetails(for: item)
        #endif
    }
    
    #if os(tvOS)
    private var tvOSView: some View {
        staticDetails(for: item)
            .scrollTransition(.interactive(timingCurve: .easeOut), axis: .vertical) { content, phase in
                content
                    .offset(y: phase.isIdentity ? 0 : -200)
            }
            .frame(height: 800)
            .background {
                GeometryReader { geo in
                    if let url = ImageURLProvider.imageURL(for: item, type: .backdrop) {
                        CachedAsyncImage(url: url, targetSize: 1920)
                            .overlay(alignment: .bottom) {
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .black, location: 0),
                                        .init(color: .black.opacity(0.6), location: 0.8),
                                        .init(color: .black.opacity(0), location: 1.0)
                                    ]),
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                                .frame(height: geo.size.height / 2 + 200)
                            }
                            .scaledToFill()
                            .scrollTransition(.interactive(timingCurve: .easeOut), axis: .vertical) { content, phase in
                                content
                                    .offset(y: phase.isIdentity ? (geo.safeAreaInsets.top + geo.safeAreaInsets.bottom) : -700)
                            }
                    }
                }
            }
    }
    #endif
    
    private func fetchItems() async {
        do {
            let loaded = try await loadItemsAction()
            itemsLoaded = true
            if let item = loaded.shuffled().first {
                await MainActor.run {
                    showDetailViewModel = ShowDetailViewModel(item: item)
                    self.item = item
                }
            }
        } catch {
            print("Error loading genres: \(error)")
        }
    }
    
    #if os(tvOS)
    @Namespace var actionButtonsNamespace
    #endif
    
    @ViewBuilder
    private func staticDetails(for item: BaseItemDto) -> some View {
        HeroBackdropView(item: item, badge: "Recently Added") {
            HStack(spacing: spacing) {
                Group {
                    if item.type == .series {
                        if let showDetailViewModel = showDetailViewModel {
                            ShowPlayButton(vm: showDetailViewModel)
                        }
                    } else {
                        MoviePlayButton(item: item)
                    }
                }
                #if os(tvOS)
                .prefersDefaultFocus(in: actionButtonsNamespace)
                #endif
                
                NavigationLink(value: item) {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.glass)
                .tint(.primary)
                .buttonBorderShape(.circle)
                #if os(tvOS)
                .controlSize(.regular)
                #else
                .controlSize(.extraLarge)
                #endif
            }
            #if os(tvOS)
            .focusScope(actionButtonsNamespace)
            #endif
        }
        .frame(maxWidth: .infinity, alignment: overallAlignment)
        #if os(tvOS)
        .padding(.horizontal, 80)
        .focusSection()
        #endif
        .environment(\.colorScheme, .dark)
        .onAppear {
            Task {
                await fetchItems()
            }
        }
    }
    
    private var overallAlignment: Alignment {
        #if os(tvOS)
        .leading
        #else
        .center
        #endif
    }
    
    private var detailsPadding: CGFloat {
        #if os(tvOS)
        80
        #else
        20
        #endif
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        15
        #elseif os(macOS)
        8
        #else
        4
        #endif
    }
}
