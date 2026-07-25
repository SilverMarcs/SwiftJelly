//
//  HeroParallaxBackground.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 25.07.26.
//

#if os(tvOS)
import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

/// A full-screen backdrop for the tvOS home screen that sits behind the hero
/// content *and* the peek of the first content shelf. It parallaxes upward at a
/// fraction of the scroll speed and fades out as the user scrolls past the
/// showcase, mirroring the Apple TV+ home experience.
struct HeroParallaxBackground: View {
    let item: BaseItemDto?
    let scrollOffset: CGFloat
    let showcaseHeight: CGFloat

    /// How much of the scroll distance the backdrop travels. Lower = more depth.
    private let parallaxFactor: CGFloat = 0.35
    /// Extra height beyond the screen so the upward parallax never reveals a gap.
    private let overscan: CGFloat = 320

    var body: some View {
        GeometryReader { proxy in
            let progress = max(0, scrollOffset)
            let fade = 1 - min(1, progress / showcaseHeight)

            ZStack(alignment: .top) {
                if let item, let url = ImageURLProvider.imageURL(for: item, type: .backdrop) {
                    CachedAsyncImage(url: url, targetSize: 1920)
                        .scaledToFill()
                        .frame(
                            width: proxy.size.width,
                            height: proxy.size.height + overscan,
                            alignment: .top
                        )
                        .clipped()
                        .overlay {
                            // Darken the lower portion so hero text and the
                            // shelf peek stay legible over bright artwork.
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .black, location: 0.0),
                                    .init(color: .black.opacity(0.5), location: 0.35),
                                    .init(color: .black.opacity(0.0), location: 0.75)
                                ]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        }
                        .offset(y: -progress * parallaxFactor)
                        .opacity(fade)
                        .id(url)
                        .transition(.opacity)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            .clipped()
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.5), value: item?.id)
    }
}
#endif
