import SwiftUI

/// Native paging supplies motion; only the visible page and its neighbors own hero content.
struct LayeredPagingCarousel<Content: View>: View {
    let ids: [String]
    @Binding var selection: String?
    @Binding var scrollPhase: ScrollPhase
    @ViewBuilder var content: (String, CGSize) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visibleIndex = 0

    var body: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width, 1)
            let maximumBlur: CGFloat = reduceMotion ? 0 : 3
            let selectedIndex = ids.firstIndex(of: selection ?? "") ?? 0
            let renderedIndices = LayeredCarouselMetrics.renderedIndices(
                visibleIndex: visibleIndex, selectedIndex: selectedIndex, count: ids.count
            )

            #if os(tvOS)
            // Keep the departing page alive until arrow-driven animation finishes.
            ZStack {
                ForEach(ids.enumerated(), id: \.element) { index, id in
                    if renderedIndices.contains(index) {
                        LayeredCarouselPage(size: geometry.size) { content(id, geometry.size) }
                            .modifier(LayeredCarouselEffect(
                                index: index,
                                progress: CGFloat(selectedIndex),
                                maximumBlur: maximumBlur
                            ))
                            .zIndex(Double(-index))
                    }
                }
            }
            .clipped()
            .task(id: selection) {
                do {
                    try await Task.sleep(for: .milliseconds(650))
                    visibleIndex = selectedIndex
                } catch { }
            }
            #else
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(ids.enumerated(), id: \.element) { index, id in
                        // Empty anchors preserve paging without retaining every image and effect.
                        Color.clear
                            .frame(width: width, height: geometry.size.height)
                            .overlay {
                                if renderedIndices.contains(index) {
                                    LayeredCarouselPage(size: geometry.size) { content(id, geometry.size) }
                                }
                            }
                            .visualEffect { content, proxy in
                                let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
                                let relativeProgress = max(min(minX / width, 1), -1)
                                // Cancel native page travel. Cross-fade in place so metadata
                                // never rises or changes scale as a page comes into view.
                                return content
                                    .blur(radius: LayeredCarouselMetrics.blurRadius(
                                        relativeProgress: relativeProgress, maximumRadius: maximumBlur
                                    ))
                                    .offset(x: -minX)
                                    .opacity(1 + min(relativeProgress, 0))
                            }
                            .zIndex(Double(-index))
                            .id(id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $selection)
            .scrollIndicators(.hidden)
            // Observe page boundaries, not every pixel. Fade and drift stay in visualEffect.
            .onScrollGeometryChange(for: Int.self) { geometry in
                let progress = (geometry.contentOffset.x + geometry.contentInsets.leading) / width
                return Int(LayeredCarouselMetrics.clampedProgress(progress, count: ids.count).rounded(.down))
            } action: { _, newIndex in
                visibleIndex = newIndex
            }
            .onScrollPhaseChange { _, newPhase in
                scrollPhase = newPhase
            }
            #endif
        }
    }
}
