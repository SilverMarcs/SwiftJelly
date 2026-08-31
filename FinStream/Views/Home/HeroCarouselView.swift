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

    #if os(tvOS)
    @State private var navigationButtonToRetain: HeroCarouselNavigationButton?
    @FocusState private var focusedNavigationButton: HeroCarouselNavigationButton?
    #endif

    private var currentIndex: Int {
        guard let scrolledID else { return 0 }
        return items.firstIndex { $0.id == scrolledID } ?? 0
    }

    var body: some View {
        ZStack {
            if !items.isEmpty {
                let activeIndex = currentIndex
                if activeIndex >= 0 && activeIndex < items.count {
                    let activeItem = items[activeIndex]
                    let activeBinding = activeItemBinding(for: activeIndex)
                    
                    Group {
                        #if !os(tvOS)
                        MediaNavigationLink(item: activeItem) {
                            hero(item: activeBinding)
                        }
                        #else
                        hero(item: activeBinding)
                            .focusSection()
                            .focused($focusedHeroID, equals: activeItem.id ?? "")
                            .scrollTransition(.interactive(timingCurve: .easeOut), axis: .vertical) { content, phase in
                                content.offset(y: phase.isIdentity ? 0 : -200)
                            }
                            .frame(maxHeight: .infinity)
                            .background {
                                GeometryReader { geo in
                                    if let url = ImageURLProvider.imageURL(for: activeItem, type: .backdrop) {
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
                    .id(activeItem.id)
                    .transition(.opacity)
                }
            }
        }
        #if os(iOS)
        .stretchy()
        #endif
        #if os(tvOS)
        .ignoresSafeArea()
        #else
        .overlay {
            if items.count > 1 {
                HStack {
                    Button {
                        scrollToPrevious()
                        startAutoScroll()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(currentIndex <= 0)

                    Spacer()

                    Button {
                        scrollToNext()
                        startAutoScroll()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(currentIndex >= items.count - 1)
                }
                .buttonBorderShape(.circle)
                .buttonStyle(.glass)
                .controlSize(.large)
                .padding(.horizontal, 16)
            }
        }
        #endif
        .onAppear {
            if scrolledID == nil, !items.isEmpty {
                scrolledID = items.first?.id
            }
            startAutoScroll()
        }
        .onDisappear { stopAutoScroll() }
        .onChange(of: scrolledID) { _, _ in startAutoScroll() }
        .onChange(of: focusedHeroID) { _, newID in
            guard let newID, !newID.isEmpty, newID != scrolledID else { return }
            withAnimation(.easeInOut(duration: 0.6)) { scrolledID = newID }
        }
        .onChange(of: items.count) { _, newCount in
            // When items first populate, nudge to the second item so the
            // carousel feels alive (matches the original trending behavior).
            if scrolledID == nil, newCount > 1 {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(300))
                    withAnimation(.easeInOut(duration: 0.6)) { scrolledID = items[1].id }
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
                heroActionRow {
                    MovieHeroActions(movie: item)
                }
            }
        case .series:
            HeroBackdropView(item: item.wrappedValue) {
                heroActionRow {
                    ShowHeroActions(show: item)
                }
            }
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func heroActionRow<Actions: View>(@ViewBuilder actions: () -> Actions) -> some View {
        #if os(tvOS)
        HStack(spacing: 15) {
            actions()

            if items.count > 1 {
                HeroCarouselNavigationButtons(
                    focusedButton: $focusedNavigationButton,
                    showsPrevious: currentIndex > 0,
                    showsNext: currentIndex < items.count - 1,
                    showPrevious: { navigate(using: .previous) },
                    showNext: { navigate(using: .next) }
                )
            }
        }
        #else
        actions()
        #endif
    }

    private func activeItemBinding(for index: Int) -> Binding<BaseItemDto> {
        Binding(
            get: {
                if index >= 0 && index < items.count {
                    return items[index]
                }
                return BaseItemDto()
            },
            set: { newValue in
                if index >= 0 && index < items.count {
                    items[index] = newValue
                }
            }
        )
    }

    private func scrollToPrevious() {
        guard currentIndex > 0 else { return }
        withAnimation(.easeInOut(duration: 0.6)) {
            scrolledID = items[currentIndex - 1].id
        }
    }

    private func scrollToNext() {
        guard currentIndex < items.count - 1 else { return }
        withAnimation(.easeInOut(duration: 0.6)) {
            scrolledID = items[currentIndex + 1].id
        }
    }

    #if os(tvOS)
    private func navigate(using button: HeroCarouselNavigationButton) {
        guard items.count > 1 else { return }

        let destinationIndex: Int
        switch button {
        case .previous:
            guard currentIndex > 0 else { return }
            destinationIndex = currentIndex - 1
        case .next:
            guard currentIndex < items.count - 1 else { return }
            destinationIndex = currentIndex + 1
        }

        withAnimation(.easeInOut(duration: 0.6)) {
            scrolledID = items[destinationIndex].id
        }
        retainNavigationFocus(
            on: navigationButtonToRetain(
                preferred: button,
                afterMovingTo: destinationIndex
            )
        )
    }

    private func navigationButtonToRetain(
        preferred button: HeroCarouselNavigationButton,
        afterMovingTo index: Int
    ) -> HeroCarouselNavigationButton {
        switch button {
        case .previous where index > 0:
            .previous
        case .next where index < items.count - 1:
            .next
        case .previous:
            .next
        case .next:
            .previous
        }
    }

    private func retainNavigationFocus(on button: HeroCarouselNavigationButton) {
        navigationButtonToRetain = button
        Task { @MainActor in
            await Task.yield()
            guard navigationButtonToRetain == button else { return }
            focusedNavigationButton = button
            navigationButtonToRetain = nil
        }
    }
    #endif

    private func startAutoScroll() {
        autoScrollTask?.cancel()
        guard items.count > 1 else { return }
        autoScrollTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled else { return }
                let nextIndex = (currentIndex + 1) % items.count
                let nextID = items[nextIndex].id
                withAnimation(.easeInOut(duration: 0.6)) {
                    scrolledID = nextID
                }

                #if os(tvOS)
                if let focusedNavigationButton {
                    retainNavigationFocus(
                        on: navigationButtonToRetain(
                            preferred: focusedNavigationButton,
                            afterMovingTo: nextIndex
                        )
                    )
                }
                #endif

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
