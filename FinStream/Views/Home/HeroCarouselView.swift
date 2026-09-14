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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    @State private var scrollPhase: ScrollPhase = .idle
    @State private var isVisible = false
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

    private var itemIDs: [String] { items.compactMap(\.id) }

    private var carouselHeight: CGFloat {
        #if os(iOS)
        HeroLayoutMetrics.height(isCompact: horizontalSizeClass == .compact)
        #else
        HeroLayoutMetrics.height()
        #endif
    }

    private var pageAnimation: Animation {
        #if os(tvOS)
        .easeInOut(duration: 0.6)
        #else
        .easeInOut(duration: reduceMotion ? 0.2 : 0.6)
        #endif
    }

    var body: some View {
        #if os(tvOS)
        tvOSCarousel
        #else
        scrollCarousel
        #endif
    }

    #if !os(tvOS)
    private var scrollCarousel: some View {
        LayeredPagingCarousel(ids: itemIDs, selection: $scrolledID, scrollPhase: $scrollPhase) { id, size in
            if let index = items.firstIndex(where: { $0.id == id }) {
                let item = items[index]
                let isActive = id == (scrolledID ?? itemIDs.first)
                MediaNavigationLink(item: item) {
                    scrollHero(item: itemBinding(for: id), isActive: isActive, width: size.width)
                }
                .allowsHitTesting(isActive)
                .disabled(!isActive)
                .accessibilityHidden(!isActive)
            }
        }
        .frame(height: carouselHeight)
        .background {
            if Device.isMacOrPad, items.indices.contains(currentIndex) {
                HeroCarouselSidebarBackdrop(item: items[currentIndex])
            }
        }
        #if os(iOS)
        .stretchy()
        #endif
        #if os(macOS) || os(iOS)
        .overlay {
            if items.count > 1 {
                HStack {
                    Button {
                        scrollToPrevious()
                        startAutoScroll()
                    } label: {
                        Label("Previous Slide", systemImage: "chevron.compact.left")
                            .labelStyle(.iconOnly)
                            .padding()
                            .contentShape(.rect)
                    }
                    .disabled(currentIndex <= 0)

                    Spacer()

                    Button {
                        scrollToNext()
                        startAutoScroll()
                    } label: {
                        Label("Next Slide", systemImage: "chevron.compact.right")
                            .labelStyle(.iconOnly)
                            .padding()
                            .contentShape(.rect)
                    }
                    .disabled(currentIndex >= items.count - 1)
                }
                .buttonStyle(.plain)
                .font(.title.weight(.light))
                .foregroundStyle(.white.opacity(0.7))
            }
        }
        #endif
        .onAppear {
            isVisible = true
            reconcileSelection()
            startAutoScroll()
        }
        .onDisappear {
            isVisible = false
            stopAutoScroll()
        }
        .onChange(of: scrolledID) { _, _ in startAutoScroll() }
        .onChange(of: focusedHeroID) { _, newID in
            guard let newID, !newID.isEmpty, newID != scrolledID else { return }
            withAnimation(pageAnimation) { scrolledID = newID }
        }
        .onChange(of: itemIDs) { _, _ in
            reconcileSelection()
            startAutoScroll()
        }
        .onChange(of: scrollPhase) { _, phase in
            if phase == .idle {
                startAutoScroll()
            } else {
                stopAutoScroll()
            }
        }
        .onChange(of: reduceMotion) { _, _ in startAutoScroll() }
    }
    #endif

    #if os(tvOS)
    private var tvOSCarousel: some View {
        ZStack {
            if !items.isEmpty, items.indices.contains(currentIndex) {
                let activeItem = items[currentIndex]
                let activeBinding = activeItemBinding(for: currentIndex)

                legacyTVHero(item: activeBinding)
                    .focusSection()
                    .focused($focusedHeroID, equals: activeItem.id ?? "")
                    .scrollTransition(.interactive(timingCurve: .easeOut), axis: .vertical) { content, phase in
                        content.offset(y: phase.isIdentity ? 0 : -200)
                    }
                    .frame(maxHeight: .infinity)
                    .background {
                        GeometryReader { geometry in
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
                                        .frame(height: geometry.size.height / 2 + 200)
                                    }
                                    .scaledToFill()
                                    .scrollTransition(.interactive(timingCurve: .easeOut), axis: .vertical) { content, phase in
                                        content.offset(y: phase.isIdentity ? (geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom) : -700)
                                    }
                            }
                        }
                    }
                    .id(activeItem.id)
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea()
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
            withAnimation(pageAnimation) { scrolledID = newID }
        }
        .onChange(of: items.count) { _, newCount in
            if scrolledID == nil, newCount > 1 {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(300))
                    withAnimation(pageAnimation) { scrolledID = items[1].id }
                }
            }
            startAutoScroll()
        }
    }
    #endif

    private func reconcileSelection() {
        if !itemIDs.contains(scrolledID ?? "") {
            scrolledID = itemIDs.first
        }
    }

    @ViewBuilder
    private func scrollHero(item: Binding<BaseItemDto>, isActive: Bool, width: CGFloat) -> some View {
        switch item.wrappedValue.type {
        case .movie:
            HeroBackdropView(
                item: item.wrappedValue,
                contentOpacity: isActive && scrollPhase != .interacting ? 1 : 0,
                carouselWidth: width
            ) {
                if isActive {
                    heroActionRow {
                        MovieHeroActions(movie: item)
                    }
                }
            }
        case .series:
            HeroBackdropView(
                item: item.wrappedValue,
                contentOpacity: isActive && scrollPhase != .interacting ? 1 : 0,
                carouselWidth: width
            ) {
                if isActive {
                    heroActionRow {
                        ShowHeroActions(show: item)
                    }
                }
            }
        default:
            EmptyView()
        }
    }

    #if os(tvOS)
    @ViewBuilder
    private func legacyTVHero(item: Binding<BaseItemDto>) -> some View {
        switch item.wrappedValue.type {
        case .movie:
            HeroBackdropView(item: item.wrappedValue, tvOSBottomPadding: 10) {
                heroActionRow { MovieHeroActions(movie: item) }
            }
        case .series:
            HeroBackdropView(item: item.wrappedValue, tvOSBottomPadding: 10) {
                heroActionRow { ShowHeroActions(show: item) }
            }
        default:
            EmptyView()
        }
    }

    private func activeItemBinding(for index: Int) -> Binding<BaseItemDto> {
        Binding(
            get: { items.indices.contains(index) ? items[index] : BaseItemDto() },
            set: { newValue in
                if items.indices.contains(index) { items[index] = newValue }
            }
        )
    }
    #endif

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

    private func itemBinding(for id: String) -> Binding<BaseItemDto> {
        Binding(
            get: { items.first { $0.id == id } ?? BaseItemDto() },
            set: { newValue in
                if let index = items.firstIndex(where: { $0.id == id }) {
                    items[index] = newValue
                }
            }
        )
    }

    private func scrollToPrevious() {
        guard currentIndex > 0 else { return }
        withAnimation(pageAnimation) {
            scrolledID = items[currentIndex - 1].id
        }
    }

    private func scrollToNext() {
        guard currentIndex < items.count - 1 else { return }
        withAnimation(pageAnimation) {
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

        withAnimation(pageAnimation) {
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
        #if os(tvOS)
        guard items.count > 1 else { return }
        autoScrollTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled else { return }
                let nextIndex = (currentIndex + 1) % items.count
                let nextID = items[nextIndex].id
                withAnimation(pageAnimation) { scrolledID = nextID }

                if let focusedNavigationButton {
                    retainNavigationFocus(
                        on: navigationButtonToRetain(
                            preferred: focusedNavigationButton,
                            afterMovingTo: nextIndex
                        )
                    )
                }
                if focusedHeroID != nil { focusedHeroID = nextID }
            }
        }
        #else
        guard isVisible, items.count > 1, scrollPhase == .idle, !reduceMotion else { return }
        autoScrollTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled, items.count > 1 else { return }
                let nextIndex = (currentIndex + 1) % items.count
                let nextID = items[nextIndex].id
                withAnimation(pageAnimation) {
                    scrolledID = nextID
                }
            }
        }
        #endif
    }

    private func stopAutoScroll() {
        autoScrollTask?.cancel()
        autoScrollTask = nil
    }
}
