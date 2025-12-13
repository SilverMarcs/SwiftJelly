import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct CoverOverlayView<ItemDetailContent: View>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    let item: BaseItemDto
    @ViewBuilder let itemDetailContent: ItemDetailContent

    var body: some View {
        VStack(alignment: coverAlignment, spacing: 20) {
            Spacer()

            if let url = ImageURLProvider.imageURL(for: item, type: .logo) {
                CachedAsyncImage(url: url, targetSize: 450)
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
            
            itemDetailContent

            OverviewView(item: item)
            
            AttributesView(item: item)
        }
        .scenePadding(.horizontal)
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: logoAlignment, vertical: .center))
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

    private var coverAlignment: HorizontalAlignment {
    #if os(tvOS)
        .leading
    #else
        .center
    #endif
    }
}
