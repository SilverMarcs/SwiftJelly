import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct HeroBackdropView<HeroActions: View>: View {
    @ViewBuilder let heroActions: HeroActions

    let item: BaseItemDto
    let logoItem: BaseItemDto
    let badge: String?

    init(
        item: BaseItemDto,
        logoItem: BaseItemDto? = nil,
        badge: String? = nil,
        @ViewBuilder heroActions: () -> HeroActions
    ) {
        self.item = item
        self.logoItem = logoItem ?? item
        self.badge = badge
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
        backdropImage
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
            targetSize: 2000
        )
        
        GeometryReader { geo in
            VStack(spacing: 0) {
                backdrop
                    .scaledToFill()
                    .frame(width: geo.size.width, height: backdropHeight, alignment: .top)
                    .clipped()

                if isCompactSize {
                    backdrop
                        .scaledToFill()
                        .frame(width: geo.size.width, height: backdropHeight, alignment: .top)
                        .scaleEffect(x: 1, y: -1, anchor: .center)
                        .frame(
                            width: geo.size.width,
                            height: reflectionHeight,
                            alignment: .top
                        )
                        .clipped()
                }
            }
            .scrollTransition(axis: .vertical) { content, phase in
                 content
                    .offset(y: phase.isIdentity ? 0 : phase.value * -200)
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
            .backgroundExtensionEffect()
            .stretchy()
        }
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

            OverviewView(item: item, compact: true)

            AttributesView(item: item)
        }
        .frame(maxWidth: .infinity, alignment: overallAlignment)
    }

    private var genreList: some View {
        let genres = item.genres ?? []
        let display = genres.isEmpty
            ? "Genre \u{00B7} Another Genre \u{00B7} Third"
            : genres.joined(separator: " \u{00B7} ")
        return Text(display)
            .font(genreFont)
            .foregroundStyle(.white.opacity(0.7))
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
                    OverviewView(item: item)
                        .frame(maxWidth: descriptionMaxWidth)

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
        isCompactSize ? 440 : 500
    }
}

