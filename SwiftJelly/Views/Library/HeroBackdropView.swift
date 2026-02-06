import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct HeroBackdropView<HeroActions: View>: View {
    let item: BaseItemDto
    @ViewBuilder let heroActions: HeroActions
    
    var body: some View {
        #if os(tvOS)
        // On tvOS, DetailView provides the backdrop as a background with blur effects
        tvOverlayContent
            .environment(\.colorScheme, .dark)
        #else
        backdropImage
            .overlay(alignment: .bottomLeading) {
                overlayContent
                    .padding()
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
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(.regularMaterial)
                    .mask {
                        bottomGradient
                    }
                    .frame(height: reflectionHeight + 150)
            }
            .backgroundExtensionEffect()
            .stretchy()
        }
        .frame(height: backdropHeight + reflectionHeight)
    }
    
    let bottomGradient = LinearGradient(
        gradient: Gradient(stops: [
            .init(color: .white, location: 0),
            .init(color: .white.opacity(1), location: 0.6),
            .init(color: .white.opacity(0), location: 1.0)
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
        if let url = ImageURLProvider.imageURL(for: item, type: .logo) {
            CachedAsyncImage(url: url, targetSize: 450) {
                Color.clear
            }
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: logoWidth, maxHeight: logoHeight, alignment: logoAlignment)
            .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(item.name ?? "Unknown")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 4)
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
    
    private var tvOverlayContent: some View {
        VStack(alignment: contentAlignment, spacing: 20) {
            Spacer()

            logo
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 30) {
                    OverviewView(item: item)
                        .frame(maxWidth: 700)

                    heroActions
                }

                Spacer()

                AttributesView(item: item)
            }
        }
        .scenePadding(.horizontal)
        .frame(maxWidth: .infinity, alignment: overallAlignment)
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
        .center
    #endif
    }
    
    private var logoAlignment: Alignment {
    #if os(tvOS)
        .bottomLeading
    #else
        .center
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
        300
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
    
    private var backdropHeight: CGFloat { 400 }
}

