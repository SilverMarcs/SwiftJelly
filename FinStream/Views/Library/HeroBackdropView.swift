import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

private extension View {
    /// Constrains width to the enclosing scroll container on platforms where
    /// `containerRelativeFrame` is well-supported. macOS and iPadOS get a no-op since they
    /// can crash inside ScrollView + backgroundExtensionEffect compositions or bleed/exceed boundaries in split views.
    @ViewBuilder
    func boundToContainerWidth(carouselWidth: CGFloat?) -> some View {
        if let carouselWidth {
            self.frame(width: carouselWidth)
        } else if Device.isMacOrPad {
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
    let contentOpacity: Double
    let carouselWidth: CGFloat?
    let tvOSBottomPadding: CGFloat

    private var isCarousel: Bool { carouselWidth != nil }

    init(
        item: BaseItemDto,
        logoItem: BaseItemDto? = nil,
        genreItem: BaseItemDto? = nil,
        badge: String? = nil,
        contentOpacity: Double = 1,
        carouselWidth: CGFloat? = nil,
        tvOSBottomPadding: CGFloat = 40,
        @ViewBuilder heroActions: () -> HeroActions
    ) {
        self.item = item
        self.logoItem = logoItem ?? item
        self.genreItem = genreItem ?? item
        self.badge = badge
        self.contentOpacity = contentOpacity
        self.carouselWidth = carouselWidth
        self.tvOSBottomPadding = tvOSBottomPadding
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
            .modifier(HeroCarouselMetadataFade(opacity: contentOpacity, isCarousel: isCarousel))
            .padding([.top, .horizontal], 40)
            .padding(.bottom, tvOSBottomPadding)
            .environment(\.colorScheme, .dark)
    #else
        backdropImage
            // Crop artwork to the viewport before sizing metadata; a scaled-to-fill image
            // can otherwise report its wider intrinsic size to the overlay.
            .frame(width: carouselWidth)
            .overlay(alignment: .bottomLeading) {
                if isCompactSize {
                    overlayContent
                        .modifier(HeroCarouselMetadataFade(opacity: contentOpacity, isCarousel: isCarousel))
                        .padding()
                } else {
                    largeScreenContent
                        .modifier(HeroCarouselMetadataFade(opacity: contentOpacity, isCarousel: isCarousel))
                        #if os(macOS)
                        .padding([.top, .horizontal])
                        .padding(.bottom, 25)
                        #else
                        .padding()
                        #endif
                }
            }
            .environment(\.colorScheme, .dark)
    #endif
    }
    
    // MARK: - Backdrop
    
    @ViewBuilder
    private var backdropImage: some View {
        let reflectionHeight = HeroLayoutMetrics.reflectionHeight
        let backdrop = CachedAsyncImage(
            url: ImageURLProvider.imageURL(for: item, type: .backdrop),
            targetSize: 1500
        )
        
        VStack(spacing: 0) {
            backdrop
                .scaledToFill()
                .boundToContainerWidth(carouselWidth: carouselWidth)
                .frame(height: backdropHeight, alignment: .top)
                .clipped()

            if isCompactSize {
                backdrop
                    .scaledToFill()
                    .boundToContainerWidth(carouselWidth: carouselWidth)
                    .frame(height: backdropHeight, alignment: .top)
                    .scaleEffect(x: 1, y: -1, anchor: .center)
                    .frame(height: reflectionHeight, alignment: .top)
                    .clipped()
            }
        }
            .scrollTransition(axis: .vertical) { content, phase in
                 content
                    .offset(y: isCarousel || phase.isIdentity ? 0 : phase.value * -200)
             }
            .overlay(alignment: .bottom) {
                if isCompactSize {
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .black.opacity(0.9), location: 0),
                            .init(color: .black.opacity(0.81), location: 0.4),
                            .init(color: .black.opacity(0), location: 1.0)
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: reflectionHeight + 150)
                } else {
                    #if os(macOS)
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
                    #else
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .black.opacity(0.9), location: 0),
                            .init(color: .black.opacity(0.81), location: 0.4),
                            .init(color: .black.opacity(0), location: 1.0)
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                        .frame(height: 300)
                    #endif
                }
            }
        .modifier(HeroBackdropScrollEffects(isCarousel: isCarousel))
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
    }
    
    private var overlayContent: some View {
        VStack(alignment: contentAlignment, spacing: 20) {
            Spacer()

            logo

            genreList

            heroActions

            if !isCarousel {
                OverviewView(item: item, compact: true)
            }

            AttributesView(item: item)
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
            .fontWeight(.medium)
            .multilineTextAlignment(isCompactSize ? .center : .leading)
            .lineLimit(isCompactSize ? 2 : nil)
            .foregroundStyle(.primary)
            .redacted(reason: genres.isEmpty ? .placeholder : [])
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
                    if !isCarousel {
                        OverviewView(item: item)
                            .frame(maxWidth: descriptionMaxWidth)
                    }

                    heroActions
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 12) {
                    AttributesView(item: item)
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
        HeroLayoutMetrics.height(isCompact: isCompactSize)
            - (isCompactSize ? HeroLayoutMetrics.reflectionHeight : 0)
    }
}
