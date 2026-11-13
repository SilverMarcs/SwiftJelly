import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

private extension View {
    /// `containerRelativeFrame` can crash inside ScrollView + `backgroundExtensionEffect`
    /// on macOS and iPadOS, or exceed split view bounds.
    @ViewBuilder
    func boundToContainerWidth() -> some View {
        if Device.isMacOrPad {
            frame(maxWidth: .infinity)
        } else {
            containerRelativeFrame(.horizontal)
        }
    }
}

private extension View {
    /// Masks the bottom of the backdrop so it fades to transparent instead of ending in a hard edge.
    func fadeOutBottom() -> some View {
        mask {
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.6),
                    .init(color: .black.opacity(0.5), location: 0.82),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

struct HeroBackdropImage: View {
    enum Parallax {
        case vertical
        /// `overscan` widens the image so the horizontal pan never reveals an edge.
        case horizontal(factor: CGFloat, overscan: CGFloat)
    }

    let item: BaseItemDto
    let isCompact: Bool
    let backdropHeight: CGFloat
    let reflectionHeight: CGFloat
    let parallax: Parallax

    private var totalHeight: CGFloat {
        isCompact ? backdropHeight + reflectionHeight : backdropHeight
    }

    var body: some View {
        switch parallax {
        case .vertical:
            verticalBackdrop
        case .horizontal(let factor, let overscan):
            horizontalBackdrop(factor: factor, overscan: overscan)
        }
    }

    private var verticalBackdrop: some View {
        imageStack(
            backdropImage
                .scaledToFill()
                .boundToContainerWidth()
        )
        .scrollTransition(axis: .vertical) { content, phase in
            content
                .offset(y: phase.isIdentity ? 0 : phase.value * -200)
        }
        .backgroundExtensionEffect()
        #if os(iOS)
        .stretchy()
        #endif
        .frame(height: totalHeight)
    }

    private func horizontalBackdrop(factor: CGFloat, overscan: CGFloat) -> some View {
        imageStack(
            backdropImage
                .scaledToFill()
                // Read from the scroll container each layout pass; a cached width collapses to zero after lazy recycling.
                .containerRelativeFrame(.horizontal) { length, _ in length * overscan }
        )
        .visualEffect { content, proxy in
            let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
            return content.offset(x: -minX * factor)
        }
        .backgroundExtensionEffect()
        .containerRelativeFrame(.horizontal)
        .frame(height: totalHeight)
        .clipped()
    }

    private func imageStack(_ image: some View) -> some View {
        VStack(spacing: 0) {
            if isCompact {
                // Fade the image itself out rather than darkening it, so there's no hard edge.
                image
                    .frame(height: backdropHeight, alignment: .top)
                    .clipped()
                    .fadeOutBottom()

                Spacer(minLength: reflectionHeight)
            } else {
                image
                    .frame(height: backdropHeight, alignment: .top)
                    .clipped()
                    .overlay(alignment: .bottom) { imageGradient }
            }
        }
        // The hero is always dark, so the image fades into black in light mode too.
        .background(isCompact ? .black : .clear)
    }

    private var backdropImage: some View {
        CachedAsyncImage(
            url: ImageURLProvider.imageURL(for: item, type: .backdrop),
            targetSize: 1500
        )
    }

    private var imageGradient: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .black, location: 0),
                .init(color: .black.opacity(0.5), location: 0.4),
                .init(color: .black.opacity(0), location: 1.0)
            ]),
            startPoint: .bottom,
            endPoint: .top
        )
        .frame(height: 300)
        .allowsHitTesting(false)
    }
}
