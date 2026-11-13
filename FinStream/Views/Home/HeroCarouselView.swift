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

    #if os(tvOS)
    @Binding var belowFold: Bool
    @Binding var backdropItem: BaseItemDto?
    #endif

    @State private var scrolledID: String?
    @State private var autoScrollTask: Task<Void, Never>?

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var scrollX: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var isUserScrolling = false
    @State private var isVisible = false
    /// The page shown by the page control. Only updated once a swipe settles, so the control
    /// isn't pulled back to the old page halfway through an animated scroll.
    @State private var currentPage = 0
    private let autoScrollInterval: Double = 8
    #endif

    #if os(tvOS)
    @Namespace private var heroNamespace
    @FocusState private var playButtonFocused: Bool
    @State private var navigationButtonToRetain: HeroCarouselNavigationButton?
    @FocusState private var focusedNavigationButton: HeroCarouselNavigationButton?
    #endif

    private var currentIndex: Int {
        guard let scrolledID else { return 0 }
        return items.firstIndex { $0.id == scrolledID } ?? 0
    }

    var body: some View {
        #if os(iOS)
        parallaxCarousel
        #else
        crossFadeCarousel
        #endif
    }

    // MARK: - iOS

    #if os(iOS)
    private var isCompact: Bool { horizontalSizeClass == .compact }
    private var pageHeight: CGFloat { HeroLayoutMetrics.height(isCompact: isCompact) }
    private var backdropHeight: CGFloat {
        pageHeight - (isCompact ? HeroLayoutMetrics.reflectionHeight : 0)
    }

    private let parallaxFactor: CGFloat = 0.14
    /// Draws the backdrop wider than its page so the parallax pan never reveals an edge.
    private let overscanRatio: CGFloat = 1.4

    /// Continuous page position, e.g. `1.5` is halfway between pages 1 and 2.
    private var fraction: CGFloat {
        guard containerWidth > 0 else { return 0 }
        return scrollX / containerWidth
    }

    private var nearestIndex: Int {
        guard !items.isEmpty else { return 0 }
        return min(max(Int(fraction.rounded()), 0), items.count - 1)
    }

    private var parallaxCarousel: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .bottom) {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(items, id: \.id) { item in
                            MediaNavigationLink(item: item) {
                                HeroBackdropImage(
                                    item: item,
                                    isCompact: isCompact,
                                    backdropHeight: backdropHeight,
                                    reflectionHeight: HeroLayoutMetrics.reflectionHeight,
                                    parallax: .horizontal(factor: parallaxFactor, overscan: overscanRatio)
                                )
                            }
                            // A GeometryReader width can stick at zero after the lazy page is recycled.
                            .containerRelativeFrame(.horizontal)
                            .id(item.id)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.paging)
                .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.x } action: { _, newX in
                    scrollX = newX
                }
                .onScrollGeometryChange(for: CGFloat.self) { $0.containerSize.width } action: { _, newWidth in
                    containerWidth = newWidth
                }
                .onScrollPhaseChange { _, newPhase in
                    isUserScrolling = newPhase != .idle
                    if newPhase == .idle {
                        currentPage = nearestIndex
                    }
                }
                .stretchy()

                detailsLayer

                if items.count > 1 {
                    paginator(proxy: proxy)
                        .padding(.bottom, 12)
                }
            }
        }
        .frame(height: pageHeight)
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }

    /// Foreground content stays in place and cross-fades with the scroll position.
    private var detailsLayer: some View {
        ZStack {
            ForEach(items.indices, id: \.self) { index in
                let distance = abs(CGFloat(index) - fraction)
                if distance < 1 {
                    hero(item: itemBinding(at: index), showsBackground: false)
                        .opacity(Double(1 - distance * 2))
                        .allowsHitTesting(index == nearestIndex)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, items.count > 1 ? 36 : 0)
        .allowsHitTesting(!isUserScrolling)
    }

    /// The system page control: its timer advances the carousel, and tapping or scrubbing the dots jumps to a page.
    private func paginator(proxy: ScrollViewProxy) -> some View {
        TimedPageControl(
            numberOfPages: items.count,
            currentPage: min(currentPage, max(items.count - 1, 0)),
            duration: autoScrollInterval,
            isPaused: isUserScrolling || !isVisible,
            tint: .white
        ) { newPage, isScrubbing in
            guard items.indices.contains(newPage) else { return }
            currentPage = newPage
            // Scrubbing jumps straight to each page, like the Apple TV app; an animated scroll per
            // step would settle on in-between pages and drag the control back.
            var transaction = Transaction(animation: isScrubbing ? nil : .easeInOut(duration: 0.4))
            transaction.disablesAnimations = isScrubbing
            withTransaction(transaction) {
                proxy.scrollTo(items[newPage].id, anchor: .leading)
            }
        }
    }
    #endif

    // MARK: - tvOS / macOS

    #if !os(iOS)
    private var crossFadeCarousel: some View {
        ZStack {
            if items.indices.contains(currentIndex) {
                let activeItem = items[currentIndex]
                let activeBinding = itemBinding(at: currentIndex)

                Group {
                    #if os(tvOS)
                    hero(item: activeBinding)
                        .focusSection()
                        .frame(maxHeight: .infinity)
                        .scrollTransition(.interactive(timingCurve: .easeOut), axis: .vertical) { content, phase in
                            content.offset(y: phase.isIdentity ? 0 : -120)
                        }
                    #else
                    MediaNavigationLink(item: activeItem) {
                        hero(item: activeBinding)
                    }
                    #endif
                }
                .id(activeItem.id)
                .transition(.opacity)
            }
        }
        #if os(tvOS)
        .padding(.horizontal, 40)
        .ignoresSafeArea()
        #else
        .overlay {
            if items.count > 1 {
                HStack {
                    Button {
                        scrollToPrevious()
                        startAutoScroll()
                    } label: {
                        Label("Previous Slide", systemImage: "chevron.left")
                            .labelStyle(.iconOnly)
                    }
                    .disabled(currentIndex <= 0)

                    Spacer()

                    Button {
                        scrollToNext()
                        startAutoScroll()
                    } label: {
                        Label("Next Slide", systemImage: "chevron.right")
                            .labelStyle(.iconOnly)
                    }
                    .disabled(currentIndex >= items.count - 1)
                }
                .buttonBorderShape(.circle)
                .buttonStyle(.glass)
                .foregroundStyle(.primary)
                .controlSize(.large)
                .padding(.horizontal, 16)
            }
        }
        #endif
        .onAppear {
            reconcileSelection()
            #if os(tvOS)
            updateBackdrop()
            if !belowFold { focusPlayButton() }
            #endif
            startAutoScroll()
        }
        .onDisappear { stopAutoScroll() }
        .onChange(of: scrolledID) { _, _ in
            #if os(tvOS)
            updateBackdrop()
            #endif
            startAutoScroll()
        }
        #if os(tvOS)
        .onChange(of: belowFold) { _, isBelow in
            // Fold snapping moves the viewport but not focus, so pull focus back onto the hero.
            if !isBelow { focusPlayButton() }
            startAutoScroll()
        }
        #endif
        .onChange(of: items.count) { _, _ in
            reconcileSelection()
            #if os(tvOS)
            updateBackdrop()
            if !belowFold { focusPlayButton() }
            #endif
            startAutoScroll()
        }
    }

    private func reconcileSelection() {
        if !items.contains(where: { $0.id == scrolledID }) {
            scrolledID = items.first?.id
        }
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

    private func startAutoScroll() {
        autoScrollTask?.cancel()
        guard items.count > 1 else { return }
        autoScrollTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(8))
                guard !Task.isCancelled else { return }
                #if os(tvOS)
                // Rotating while the hero is visible would rebuild it and steal focus from Play.
                guard belowFold else { continue }
                #endif
                let nextIndex = (currentIndex + 1) % items.count
                withAnimation(.easeInOut(duration: 0.6)) {
                    scrolledID = items[nextIndex].id
                }

                #if os(tvOS)
                if let focusedNavigationButton {
                    retainNavigationFocus(
                        on: navigationButtonToRetain(preferred: focusedNavigationButton, afterMovingTo: nextIndex)
                    )
                }
                #endif
            }
        }
    }
    #endif

    // MARK: - Shared

    @ViewBuilder
    private func hero(item: Binding<BaseItemDto>, showsBackground: Bool = true) -> some View {
        if let reference = item.wrappedValue.seerReference {
            HeroBackdropView(item: item.wrappedValue, showsBackground: showsBackground) {
                heroActionRow {
                    #if os(tvOS)
                    SeerCarouselHeroActions(item: item.wrappedValue, reference: reference, externalFocusNamespace: heroNamespace, playFocus: $playButtonFocused)
                    #else
                    SeerCarouselHeroActions(item: item.wrappedValue, reference: reference)
                    #endif
                }
            }
        } else {
            jellyfinHero(item: item, showsBackground: showsBackground)
        }
    }

    @ViewBuilder
    private func jellyfinHero(item: Binding<BaseItemDto>, showsBackground: Bool) -> some View {
        switch item.wrappedValue.type {
        case .movie:
            HeroBackdropView(item: item.wrappedValue, showsBackground: showsBackground, showsOverview: false) {
                heroActionRow {
                    #if os(tvOS)
                    MovieHeroActions(movie: item, externalFocusNamespace: heroNamespace, playFocus: $playButtonFocused)
                    #else
                    MovieHeroActions(movie: item)
                    #endif
                }
            }
        case .series:
            HeroBackdropView(item: item.wrappedValue, showsBackground: showsBackground, showsOverview: false) {
                heroActionRow {
                    #if os(tvOS)
                    ShowHeroActions(show: item, externalFocusNamespace: heroNamespace, playFocus: $playButtonFocused)
                    #else
                    ShowHeroActions(show: item)
                    #endif
                }
            }
        case .episode:
            HeroBackdropView(
                item: item.wrappedValue,
                logoItem: item.wrappedValue.heroSeriesItem,
                genreItem: item.wrappedValue.heroSeriesItem,
                badge: item.wrappedValue.seasonEpisodeString,
                showsBackground: showsBackground
            ) {
                heroActionRow {
                    #if os(tvOS)
                    EpisodeHeroActions(episode: item, externalFocusNamespace: heroNamespace, playFocus: $playButtonFocused)
                    #else
                    EpisodeHeroActions(episode: item)
                    #endif
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

    private func itemBinding(at index: Int) -> Binding<BaseItemDto> {
        Binding(
            get: { items.indices.contains(index) ? items[index] : BaseItemDto() },
            set: { newValue in
                if items.indices.contains(index) { items[index] = newValue }
            }
        )
    }

    private func stopAutoScroll() {
        autoScrollTask?.cancel()
        autoScrollTask = nil
    }

    #if os(tvOS)
    /// `@FocusState` only moves focus on a value change, and after a navigation round trip the
    /// focus engine can leave it reading `true` while another button is focused. Clearing it first
    /// guarantees a real `false -> true` edge; the repeated assignments win against the engine's
    /// own restoration pass.
    private func focusPlayButton() {
        playButtonFocused = false
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(20))
            playButtonFocused = true
            try? await Task.sleep(for: .milliseconds(120))
            playButtonFocused = true
            try? await Task.sleep(for: .milliseconds(200))
            playButtonFocused = true
        }
    }

    private func updateBackdrop() {
        backdropItem = items.first { $0.id == scrolledID } ?? items.first
    }

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
        retainNavigationFocus(on: navigationButtonToRetain(preferred: button, afterMovingTo: destinationIndex))
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
}
