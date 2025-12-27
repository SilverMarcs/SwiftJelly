import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct HeroBackdropView<HeroActions: View>: View {
    let item: BaseItemDto
    @ViewBuilder let heroActions: HeroActions
    
    var body: some View {
        #if os(tvOS)
        // On tvOS, DetailView provides the backdrop as a background with blur effects
        overlayContent
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
    
    private var overlayContent: some View {
        VStack(alignment: logoAlignment, spacing: 20) {
            Spacer()

            if let url = ImageURLProvider.imageURL(for: item, type: .logo) {
                CachedAsyncImage(url: url, targetSize: 450) {
                    Color.clear
                }
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: logoWidth, maxHeight: logoHeight)
                .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(item.name ?? "Unknown")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4)
            }
            
            heroActions

            OverviewView(item: item)
            
            AttributesView(item: item)
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
    
    private var logoAlignment: HorizontalAlignment {
    #if os(tvOS)
        .leading
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
        300
    #else
        100
    #endif
    }
}
