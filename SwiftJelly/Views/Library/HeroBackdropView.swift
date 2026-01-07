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
    
    private var backdropImage: some View {
        CachedAsyncImage(
            url: ImageURLProvider.imageURL(for: item, type: .backdrop),
            targetSize: 2000
        )
        .scaledToFill()
        #if os(iOS)
        .containerRelativeFrame(.horizontal)
        #endif
        .frame(height: height)
        .clipped()
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.regularMaterial)
                .mask {
                    LinearGradient(
                        colors: [.white, .white.opacity(0.95), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                }
                .frame(height: 300)
        }
        .backgroundExtensionEffect()
        .stretchy()
    }
    
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
        450
    #endif
    }

    private var logoHeight: CGFloat {
    #if os(tvOS)
        150
    #else
        100
    #endif
    }
}
