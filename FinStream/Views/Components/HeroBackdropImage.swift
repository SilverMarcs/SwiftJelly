import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

private extension View {
    /// Constrains width to the enclosing scroll container on platforms where
    /// `containerRelativeFrame` is well-supported. macOS and iPadOS get a no-op since they
    /// can crash inside ScrollView + backgroundExtensionEffect compositions or bleed/exceed boundaries in split views.
    @ViewBuilder
    func boundToContainerWidth() -> some View {
        if Device.isMacOrPad {
            self.frame(maxWidth: .infinity)
        } else {
            self.containerRelativeFrame(.horizontal)
        }
    }
}

/// The backdrop artwork shared by the media detail hero (`HeroBackdropView`) and
/// the Home hero carousel. Both draw the same image, the linear gradient over the
/// image, the separate controls gradient sized for the parallax, a `Spacer`, and a
/// `backgroundExtensionEffect` that fills that spacer with a reflection. Only the
/// parallax mechanic, width sizing and outer framing differ per call site, selected
/// by `Parallax`.
struct HeroBackdropImage: View {
    enum Parallax {
        /// Detail hero: image pans vertically with the outer scroll, plus the
        /// rubber-band stretch on iOS.
        case vertical
        /// Hero carousel: image pans horizontally against its neighbours, drawn
        /// wider than the page (`overscan`) so the pan never reveals an edge gap.
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

    // MARK: - Parallax variants

    private var verticalBackdrop: some View {
        let image = backdropImage
        return VStack(spacing: 0) {
            image
                .scaledToFill()
                .boundToContainerWidth()
                .frame(height: backdropHeight, alignment: .top)
                .clipped()
                .overlay(alignment: .bottom) { imageGradient }

            if isCompact {
                Spacer(minLength: reflectionHeight)
            }
        }
        .scrollTransition(axis: .vertical) { content, phase in
            content
                .offset(y: phase.isIdentity ? 0 : phase.value * -200)
        }
        .overlay(alignment: .bottom) { controlsGradient }
        .backgroundExtensionEffect()
        #if os(iOS)
        .stretchy()
        #endif
        .frame(height: totalHeight)
    }

    private func horizontalBackdrop(factor: CGFloat, overscan: CGFloat) -> some View {
        let image = backdropImage
        return VStack(spacing: 0) {
            image
                .scaledToFill()
                // Draw the image wider than the page so the parallax pan never
                // reveals a gap at the edges. The width is taken straight from the
                // scroll container every layout pass, so it survives off-screen
                // recycling (no zero-width collapse).
                .containerRelativeFrame(.horizontal) { length, _ in length * overscan }
                .frame(height: backdropHeight, alignment: .top)
                .clipped()
                .overlay(alignment: .bottom) { imageGradient }

            if isCompact {
                Spacer(minLength: reflectionHeight)
            }
        }
        .visualEffect { content, proxy in
            let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
            return content.offset(x: -minX * factor)
        }
        .overlay(alignment: .bottom) { controlsGradient }
        .backgroundExtensionEffect()
        .containerRelativeFrame(.horizontal)
        .frame(height: totalHeight)
        .clipped()
    }

    // MARK: - Pieces

    private var backdropImage: some View {
        CachedAsyncImage(
            url: ImageURLProvider.imageURL(for: item, type: .backdrop),
            targetSize: 1500
        )
    }

    /// Darkens the lower portion of the artwork itself.
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

    /// A second gradient over the reflection/controls area on compact widths, so
    /// the foreground content stays legible as the artwork parallaxes behind it.
    @ViewBuilder
    private var controlsGradient: some View {
        if isCompact {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .black.opacity(1), location: 0),
                    .init(color: .black.opacity(0.8), location: 0.8),
                    .init(color: .black.opacity(0), location: 1.0)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: reflectionHeight + 150)
            .allowsHitTesting(false)
        }
    }
}
