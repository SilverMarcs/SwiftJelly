import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct HeroBackdropView<HeroActions: View>: View {
    @ViewBuilder let heroActions: HeroActions
    
    let item: BaseItemDto
    let badge: String?
    
    init(item: BaseItemDto, @ViewBuilder heroActions: () -> HeroActions) {
        self.item = item
        self.badge = nil
        self.heroActions = heroActions()
    }
    
    init(item: BaseItemDto, badge: String, @ViewBuilder heroActions: () -> HeroActions) {
        self.item = item
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
                    Rectangle()
                        .fill(.regularMaterial)
                        .mask {
                            bottomGradient
                        }
                        .frame(height: reflectionHeight + 150)
                } else {
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
            }
            .backgroundExtensionEffect()
            .stretchy()
        }
        .frame(height: isCompactSize ? backdropHeight + reflectionHeight : backdropHeight)
    }
    
    let bottomGradient = LinearGradient(
        gradient: Gradient(stops: [
            .init(color: .black, location: 0),
            .init(color: .black.opacity(1), location: 0.6),
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
            if let url = ImageURLProvider.imageURL(for: item, type: .logo) {
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
                
                CachedAsyncImage(url: url, targetSize: 450) {
                    Color.clear
                }
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: logoWidth, maxHeight: logoHeight, alignment: logoAlignment)
                .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(item.name ?? "")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4)
            }
        }
    }
    
    private var overlayContent: some View {
        VStack(alignment: contentAlignment, spacing: 20) {
            Spacer()

            logo

            heroActions

            OverviewView(item: item)

            AttributesView(item: item)
        }
        .frame(maxWidth: .infinity, alignment: overallAlignment)
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

                AttributesView(item: item)
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
        isCompactSize ? 380 : 500
    }
}

