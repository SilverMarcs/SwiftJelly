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
    /// Horizontal content offset of the carousel, driven by the scroll gesture.
    @State private var scrollX: CGFloat = 0
    /// Width of the scroll container, i.e. the width of a single page.
    @State private var containerWidth: CGFloat = 0
    /// Whether the user (or a programmatic animation) is actively scrolling.
    @State private var isUserScrolling = false
    /// Progress (0...1) of the current page's auto-scroll timer, driving the
    /// paginator's fill. Resets whenever the settled page changes or the user
    /// starts scrolling.
    @State private var pageProgress: CGFloat = 0
    /// Seconds each page stays before the carousel auto-advances.
    private let autoScrollInterval: Double = 8
    #endif

    #if os(tvOS)
    @Namespace private var heroNamespace
    @FocusState private var playButtonFocused: Bool
    #endif

    #if os(tvOS)
    init(items: Binding<[BaseItemDto]>, belowFold: Binding<Bool>, backdropItem: Binding<BaseItemDto?>) {
        self._items = items
        self._belowFold = belowFold
        self._backdropItem = backdropItem
    }
    #else
    init(items: Binding<[BaseItemDto]>) {
        self._items = items
    }
    #endif

    private var currentIndex: Int {
        guard let scrolledID else { return 0 }
        return items.firstIndex { $0.id == scrolledID } ?? 0
    }

    var body: some View {
        #if os(iOS)
        iosCarouselBody
        #else
        legacyBody
        #endif
    }

    // MARK: - iOS: gesture-driven parallax carousel

    #if os(iOS)
    private var isCompact: Bool { horizontalSizeClass == .compact }
    private var backdropHeight: CGFloat { isCompact ? 440 : 500 }
    private let reflectionHeight: CGFloat = 200
    /// Full page height. On compact widths the artwork extends downward into a
    /// reflection (matching `HeroBackdropView`), so the page is taller and shows a
    /// larger image.
    private var pageHeight: CGFloat { isCompact ? backdropHeight + reflectionHeight : backdropHeight }

    /// How much of the page translation the backdrop image absorbs, creating the
    /// parallax lag relative to the fixed foreground content.
    private let parallaxFactor: CGFloat = 0.14
    /// The backdrop image is drawn wider than its page so the parallax pan never
    /// reveals a gap at the edges.
    private let overscanRatio: CGFloat = 1.4

    /// Virtual page position, e.g. `1.5` means halfway between pages 1 and 2.
    private var fraction: CGFloat {
        guard containerWidth > 0 else { return 0 }
        return scrollX / containerWidth
    }

    /// The page the carousel is settled on (or nearest to).
    private var nearestIndex: Int {
        guard !items.isEmpty else { return 0 }
        let idx = Int(fraction.rounded())
        return min(max(idx, 0), items.count - 1)
    }

    private var iosCarouselBody: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .bottom) {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { _, item in
                            MediaNavigationLink(item: item) {
                                parallaxBackdrop(item)
                            }
                            // Size pages to the scroll container. Unlike a width
                            // read from a `GeometryReader` rooting this lazy child
                            // — which can stick at zero after the carousel is
                            // recycled off-screen and leave every page blank when
                            // scrolled back — `containerRelativeFrame` is resolved
                            // by the layout system on every pass, so it is always
                            // correct on reappear.
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
                        startAutoScrollIOS(proxy: proxy)
                    } else {
                        // The user (or a programmatic scroll) took over: halt
                        // the timer and wind the fill back to empty. Retarget
                        // via an explicit animation so the in-flight 8s fill is
                        // cancelled immediately instead of running to completion.
                        stopAutoScroll()
                        withAnimation(.linear(duration: 0.2)) { pageProgress = 0 }
                    }
                }
                // Only the backdrop layer gets the rubber-band stretch when
                // the home scroll is pulled down; the details stay put.
                .stretchy()

                detailsLayer

                if items.count > 1 {
                    paginator
                        .padding(.bottom, 16)
                }
            }
            .onAppear {
                startAutoScrollIOS(proxy: proxy)
            }
        }
        .frame(height: pageHeight)
        .onDisappear { stopAutoScroll() }
    }

    /// A single backdrop page, styled to match the detail hero (`HeroBackdropView`):
    /// the artwork darkens under a gradient over the image plus a separate controls
    /// gradient, and on compact widths extends into a reflection via
    /// `backgroundExtensionEffect` (a `Spacer`, not a hand-mirrored copy). The image
    /// pans slower than the page, producing horizontal parallax against its neighbours.
    private func parallaxBackdrop(_ item: BaseItemDto) -> some View {
        HeroBackdropImage(
            item: item,
            isCompact: isCompact,
            backdropHeight: backdropHeight,
            reflectionHeight: reflectionHeight,
            parallax: .horizontal(factor: parallaxFactor, overscan: overscanRatio)
        )
    }

    /// The fixed foreground content (logo, actions, description, …). It never
    /// moves horizontally; instead the current and incoming items cross-fade as
    /// a function of the scroll position.
    private var detailsLayer: some View {
        ZStack {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, _ in
                let distance = abs(CGFloat(index) - fraction)
                if distance < 1 {
                    hero(item: activeItemBinding(for: index), showsBackground: false)
                        .opacity(Double(1 - distance * 2))
                        .allowsHitTesting(index == nearestIndex)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        // Lift the details so the attributes clear the paginator sitting below.
        .padding(.bottom, items.count > 1 ? 24 : 0)
        // Let the swipe gesture reach the backdrop layer while scrolling; the
        // decorative content is individually non-interactive, so only the action
        // buttons intercept touches once settled.
        .allowsHitTesting(!isUserScrolling)
    }

    /// App Store-style paginator: a dot per page, with the active page shown as a
    /// capsule whose bright fill tracks the auto-scroll timer. The pill expands
    /// and contracts continuously with the swipe via `fraction`.
    private var paginator: some View {
        let dotHeight: CGFloat = 8
        let dotWidth: CGFloat = 8
        let activeWidth: CGFloat = 28

        return HStack(spacing: 6) {
            ForEach(items.indices, id: \.self) { index in
                // Continuous "activeness": 1 when settled on this page, 0 a full
                // page away. Driven by the live scroll fraction so the pill morphs
                // smoothly under the finger instead of snapping at the midpoint.
                let activeness = max(0, 1 - abs(fraction - CGFloat(index)))
                let trackWidth = dotWidth + (activeWidth - dotWidth) * activeness
                let isCurrent = index == nearestIndex

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: trackWidth, height: dotHeight)

                    if isCurrent {
                        // Bright timer fill, clamped to a minimum so the active
                        // page always reads as a solid nub that grows into a pill
                        // rather than vanishing when the timer is near empty.
                        Capsule()
                            .fill(Color.white)
                            .frame(width: max(dotHeight, trackWidth * pageProgress), height: dotHeight)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// Resets the paginator fill to empty and animates it linearly across the
    /// dwell interval, matching the pending auto-advance.
    private func restartPageProgress() {
        withAnimation(.linear(duration: 0.2)) { pageProgress = 0 }
        withAnimation(.linear(duration: autoScrollInterval).delay(0.2)) {
            pageProgress = 1
        }
    }

    private func startAutoScrollIOS(proxy: ScrollViewProxy) {
        autoScrollTask?.cancel()
        guard items.count > 1 else {
            pageProgress = 0
            return
        }
        restartPageProgress()
        autoScrollTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(autoScrollInterval))
                guard !Task.isCancelled, !isUserScrolling else { continue }
                let next = (nearestIndex + 1) % items.count
                withAnimation(.easeInOut(duration: 0.6)) {
                    proxy.scrollTo(items[next].id, anchor: .leading)
                }
            }
        }
    }
    #endif

    // MARK: - tvOS / macOS: single item with cross-fade + arrow controls

    #if !os(iOS)
    private var legacyBody: some View {
        ZStack {
            if !items.isEmpty {
                let activeIndex = currentIndex
                if activeIndex >= 0 && activeIndex < items.count {
                    let activeItem = items[activeIndex]
                    let activeBinding = activeItemBinding(for: activeIndex)

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
            // Returning to the top: scroll-snapping moves the viewport but not
            // focus (and the peeking shelf keeps the engine's focus on a card),
            // so drive focus back onto the hero's Play button ourselves.
            if !isBelow {
                focusPlayButton()
            }
            startAutoScroll()
        }
        #endif
        .onChange(of: items.count) { _, newCount in
            if scrolledID == nil, newCount > 0 {
                scrolledID = items.first?.id
            }
            #if os(tvOS)
            updateBackdrop()
            if !belowFold { focusPlayButton() }
            #endif
            startAutoScroll()
        }
    }
    #endif

    // MARK: - Shared

    @ViewBuilder
    private func hero(item: Binding<BaseItemDto>, showsBackground: Bool = true) -> some View {
        switch item.wrappedValue.type {
        case .movie:
            HeroBackdropView(item: item.wrappedValue, showsBackground: showsBackground) {
                #if os(tvOS)
                MovieHeroActions(movie: item, externalFocusNamespace: heroNamespace, playFocus: $playButtonFocused)
                #else
                MovieHeroActions(movie: item)
                #endif
            }
        case .series:
            HeroBackdropView(item: item.wrappedValue, showsBackground: showsBackground) {
                #if os(tvOS)
                ShowHeroActions(show: item, externalFocusNamespace: heroNamespace, playFocus: $playButtonFocused)
                #else
                ShowHeroActions(show: item)
                #endif
            }
        default:
            EmptyView()
        }
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

    #if os(tvOS)
    /// Drives focus onto the hero's Play button. `@FocusState` (unlike
    /// `resetFocus`) can move focus across focus scopes, so this reliably pulls
    /// focus off a Continue Watching card.
    ///
    /// `@FocusState` only moves focus on a *change* of value. After a navigation
    /// round-trip the focus engine restores focus itself and leaves this binding
    /// desynced — it can still read `true` while focus actually sits on another
    /// action button. Assigning `true` again would then be a no-op and focus
    /// would stay on the wrong button. So we first clear to `false`, then assert
    /// `true` after a yield to guarantee a real `false -> true` edge, re-asserting
    /// a couple of times so our request beats the focus engine's own update.
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
        if let scrolledID, let item = items.first(where: { $0.id == scrolledID }) {
            backdropItem = item
        } else {
            backdropItem = items.first
        }
    }
    #endif

    #if !os(iOS)
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
                // Only rotate while the hero is scrolled off-screen so the
                // rebuild never steals focus from the hero's Play button.
                guard belowFold else { continue }
                #endif
                let nextIndex = (currentIndex + 1) % items.count
                withAnimation(.easeInOut(duration: 0.6)) {
                    scrolledID = items[nextIndex].id
                }
            }
        }
    }
    #endif

    private func stopAutoScroll() {
        autoScrollTask?.cancel()
        autoScrollTask = nil
    }
}
