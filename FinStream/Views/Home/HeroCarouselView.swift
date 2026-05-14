//
//  HeroCarouselView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 06/05/2026.
//

import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct HeroCarouselView: View {
    @Binding var items: [BaseItemDto]

    @State private var scrolledID: String?
    @State private var autoScrollTask: Task<Void, Never>?
    @FocusState private var focusedHeroID: String?

    private var currentIndex: Int {
        guard let scrolledID else { return 0 }
        return items.firstIndex { $0.id == scrolledID } ?? 0
    }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach($items, id: \.id) { item in
                    Group {
                    #if !os(tvOS)
                    MediaNavigationLink(item: item.wrappedValue) {
                        hero(item: item)
                    }
                    #else
                    hero(item: item)
                        .focusSection()
                        .focused($focusedHeroID, equals: item.wrappedValue.id ?? "")
                        .scrollTransition(.interactive(timingCurve: .easeOut), axis: .vertical) { content, phase in
                            content.offset(y: phase.isIdentity ? 0 : -200)
                        }
                        .frame(maxHeight: .infinity)
                        .background {
                            GeometryReader { geo in
                                if let url = ImageURLProvider.imageURL(for: item.wrappedValue, type: .backdrop) {
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
                                            content.offset(y: phase.isIdentity ? (geo.safeAreaInsets.top + geo.safeAreaInsets.bottom) : -700)
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
        #if os(iOS)
        .stretchy()
        #endif
        .scrollPosition(id: $scrolledID, anchor: .center)
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        #if os(tvOS)
        .ignoresSafeArea()
        .contentMargins(.horizontal, 1, for: .scrollContent)
        #else
        .overlay {
            if items.count > 1 {
                HStack {
                    Button {
                        withAnimation { scrollToPrevious() }
                        startAutoScroll()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(currentIndex <= 0)

                    Spacer()

                    Button {
                        withAnimation { scrollToNext() }
                        startAutoScroll()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(currentIndex >= items.count - 1)
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
        .onAppear { startAutoScroll() }
        .onDisappear { stopAutoScroll() }
        .onChange(of: scrolledID) { _, _ in startAutoScroll() }
        .onChange(of: focusedHeroID) { _, newID in
            guard let newID, !newID.isEmpty, newID != scrolledID else { return }
            withAnimation { scrolledID = newID }
        }
        .onChange(of: items.count) { _, newCount in
            // When items first populate, nudge to the second item so the
            // carousel feels alive (matches the original trending behavior).
            if scrolledID == nil, newCount > 1 {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(300))
                    withAnimation { scrolledID = items[1].id }
                }
            }
            startAutoScroll()
        }
    }

    @ViewBuilder
    private func hero(item: Binding<BaseItemDto>) -> some View {
        switch item.wrappedValue.type {
        case .movie:
            HeroBackdropView(item: item.wrappedValue) {
                MovieHeroActions(movie: item)
            }
        case .series:
            HeroBackdropView(item: item.wrappedValue) {
                ShowHeroActions(show: item)
            }
        default:
            EmptyView()
        }
    }

    private func scrollToPrevious() {
        guard currentIndex > 0 else { return }
        scrolledID = items[currentIndex - 1].id
    }

    private func scrollToNext() {
        guard currentIndex < items.count - 1 else { return }
        scrolledID = items[currentIndex + 1].id
    }

    private func startAutoScroll() {
        autoScrollTask?.cancel()
        guard items.count > 1 else { return }
        autoScrollTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled else { return }
                let nextIndex = (currentIndex + 1) % items.count
                let nextID = items[nextIndex].id
                withAnimation {
                    scrolledID = nextID
                }
                // If the user is currently focused inside the carousel,
                // drag focus along to the new hero so subsequent manual
                // navigation doesn't snap the carousel backward.
                if focusedHeroID != nil {
                    focusedHeroID = nextID
                }
            }
        }
    }

    private func stopAutoScroll() {
        autoScrollTask?.cancel()
        autoScrollTask = nil
    }
}
