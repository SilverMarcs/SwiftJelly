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

struct HeroBackdropView<HeroActions: View>: View {
    @ViewBuilder let heroActions: HeroActions

    let item: BaseItemDto
    let logoItem: BaseItemDto
    let genreItem: BaseItemDto
    let badge: String?

    /// When `false`, the backdrop image is omitted and only the overlay content
    /// (logo, genres, actions, overview, attributes) is rendered over a
    /// transparent, flexible frame. Used by the iOS hero carousel, which draws a
    /// separate parallax-scrolling backdrop behind a fixed, cross-fading overlay.
    let showsBackground: Bool

    init(
        item: BaseItemDto,
        logoItem: BaseItemDto? = nil,
        genreItem: BaseItemDto? = nil,
        badge: String? = nil,
        showsBackground: Bool = true,
        @ViewBuilder heroActions: () -> HeroActions
    ) {
        self.item = item
        self.logoItem = logoItem ?? item
        self.genreItem = genreItem ?? item
        self.badge = badge
        self.showsBackground = showsBackground
        self.heroActions = heroActions()
    }

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isCompactSize: Bool {
        horizontalSizeClass == .compact
    }
    #else
    private var isCompactSize: Bool { false }
    #endif
    
    var body: some View {
    #if os(tvOS)
        largeScreenContent
            .padding(40)
            .environment(\.colorScheme, .dark)
    #else
        Group {
            if showsBackground {
                backdropImage
            } else {
                // Overlay-only mode: a flexible, non-interactive frame so the
                // details sit at the bottom, matching the height of the separate
                // backdrop the carousel scrolls behind it.
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .bottomLeading) {
            if isCompactSize {
                overlayContent
                    .padding()
            } else {
                largeScreenContent
                    .padding()
            }
        }
        .environment(\.colorScheme, .dark)
    #endif
    }
    
    // MARK: - Backdrop
    
    @ViewBuilder
    private var backdropImage: some View {
        let reflectionHeight: CGFloat = 200
        let backdrop = CachedAsyncImage(
            url: ImageURLProvider.imageURL(for: item, type: .backdrop),
            targetSize: 1500
        )
        
        VStack(spacing: 0) {
            backdrop
                .scaledToFill()
                .boundToContainerWidth()
                .frame(height: backdropHeight, alignment: .top)
                .clipped()
                .overlay(alignment: .bottom) {
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
                }

            if isCompactSize {
                Spacer(minLength: reflectionHeight)
            }
        }
            .scrollTransition(axis: .vertical) { content, phase in
                 content
                    .offset(y: phase.isIdentity ? 0 : phase.value * -200)
             }
            .overlay(alignment: .bottom) { // Additional gradient for the iOS controls for the parallax scroll
                if isCompactSize {
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
                }
            }
        .backgroundExtensionEffect()
        #if os(iOS)
        .stretchy()
        #endif
        .frame(height: isCompactSize ? backdropHeight + reflectionHeight : backdropHeight)
    }
    
    let bottomGradient = LinearGradient(
        gradient: Gradient(stops: [
            .init(color: .black, location: 0),
            .init(color: .black.opacity(0.9), location: 0.5),
            .init(color: .black.opacity(0), location: 1.0)
        ]),
        startPoint: .bottom,
        endPoint: .top
    )
    
    private var height: CGFloat {
        #if os(macOS)
        480
        #else
        620
        #endif
    }
    
    // MARK: - Overlay Content
    
    @ViewBuilder
    private var logo: some View {
        
        VStack(alignment: .center) {
            if let badge = badge {
                Text(badge)
                    .font(.subheadline)
                    .bold()
                    .opacity(0.7)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .glassEffect(in: .capsule)
                    .scaleEffect(0.8)
            }

            if let url = ImageURLProvider.imageURL(for: logoItem, type: .logo) {
                CachedAsyncImage(url: url, targetSize: 450) {
                    Color.clear
                }
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: logoWidth, maxHeight: logoHeight, alignment: logoAlignment)
                .fixedSize(horizontal: false, vertical: true)
            } else {
                let name = logoItem.name
                Text(name?.isEmpty == false ? name! : "Title Placeholder")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4)
                    .redacted(reason: name?.isEmpty == false ? [] : .placeholder)
            }
        }
        // Purely decorative: never intercept touches, so swipes over the logo
        // scroll the iOS hero carousel behind it.
        .allowsHitTesting(false)
    }
    
    private var overlayContent: some View {
        VStack(alignment: contentAlignment, spacing: 20) {
            Spacer()

            logo

            genreList

            heroActions

            OverviewView(item: item, compact: true)

            AttributesView(item: item)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, alignment: overallAlignment)
    }

    private var genreList: some View {
        let genres = genreItem.genres ?? []
        let display = genres.isEmpty
            ? "Genre \u{00B7} Another Genre \u{00B7} Third"
            : genres.joined(separator: " \u{00B7} ")
        return Text(display)
            .font(genreFont)
            .foregroundStyle(.white.opacity(0.7))
            .redacted(reason: genres.isEmpty ? .placeholder : [])
            .allowsHitTesting(false)
    }

    private var genreFont: Font {
        #if os(iOS)
        .subheadline
        #elseif os(tvOS)
        .caption
        #else
        .callout
        #endif
    }

    private var largeScreenContent: some View {
        VStack(alignment: contentAlignment, spacing: 20) {
            Spacer()

            logo

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 30) {
                    OverviewView(item: item)
                        .frame(maxWidth: descriptionMaxWidth)

                    heroActions
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 12) {
                    AttributesView(item: item)
                        .allowsHitTesting(false)
                    genreList
                }
            }
        }
        .scenePadding(.horizontal)
        .frame(maxWidth: .infinity, alignment: overallAlignment)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    private var overallAlignment: Alignment {
    #if os(tvOS)
        .leading
    #else
        .center
    #endif
    }
    
    private var contentAlignment: HorizontalAlignment {
    #if os(tvOS)
        .leading
    #else
        isCompactSize ? .center : .leading
    #endif
    }
    
    private var logoAlignment: Alignment {
    #if os(tvOS)
        .bottomLeading
    #else
        .center
    #endif
    }

    private var descriptionMaxWidth: CGFloat {
    #if os(tvOS)
        700
    #else
        400
    #endif
    }
    
    private var logoWidth: CGFloat {
    #if os(tvOS)
        450
    #else
        250
    #endif
    }

    private var logoHeight: CGFloat {
    #if os(tvOS)
        250
    #else
        140
    #endif
    }
    
    private var backdropTargetSize: CGFloat {
    #if os(tvOS)
        2000
    #else
        1080
    #endif
    }
    
    private var backdropHeight: CGFloat {
        isCompactSize ? 440 : 500
    }
}

