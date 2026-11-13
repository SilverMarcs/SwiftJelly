import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct HeroBackdropView<HeroActions: View>: View {
    @ViewBuilder let heroActions: HeroActions

    let item: BaseItemDto
    let logoItem: BaseItemDto
    let genreItem: BaseItemDto
    let badge: String?
    let showsBackground: Bool
    let showsOverview: Bool

    init(
        item: BaseItemDto,
        logoItem: BaseItemDto? = nil,
        genreItem: BaseItemDto? = nil,
        badge: String? = nil,
        showsBackground: Bool = true,
        showsOverview: Bool = true,
        @ViewBuilder heroActions: () -> HeroActions
    ) {
        self.item = item
        self.logoItem = logoItem ?? item
        self.genreItem = genreItem ?? item
        self.badge = badge
        self.showsBackground = showsBackground
        self.showsOverview = showsOverview
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
    
    private var backdropImage: some View {
        HeroBackdropImage(
            item: item,
            isCompact: isCompactSize,
            backdropHeight: backdropHeight,
            reflectionHeight: HeroLayoutMetrics.reflectionHeight,
            parallax: .vertical
        )
    }
    
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
        .allowsHitTesting(false)
    }
    
    private var overlayContent: some View {
        VStack(alignment: contentAlignment, spacing: 20) {
            Spacer()

            logo

            genreList

            heroActions

            if showsOverview {
                OverviewView(item: item, compact: true)
            }

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
            .fontWeight(.medium)
            .multilineTextAlignment(isCompactSize ? .center : .leading)
            .lineLimit(isCompactSize ? 2 : nil)
            .foregroundStyle(.primary)
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
                    if showsOverview {
                        OverviewView(item: item)
                            .frame(maxWidth: descriptionMaxWidth)
                    }

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
    
    private var backdropHeight: CGFloat {
        HeroLayoutMetrics.height(isCompact: isCompactSize)
            - (isCompactSize ? HeroLayoutMetrics.reflectionHeight : 0)
    }
}
