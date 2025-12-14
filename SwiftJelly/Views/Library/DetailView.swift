import SwiftUI
import SwiftMediaViewer
import JellyfinAPI

struct DetailView<Content: View, ItemDetailContent: View>: View {
    @Environment(\.refresh) private var refresh

    let item: BaseItemDto
    @ViewBuilder let content: Content
    @ViewBuilder let heroView: ItemDetailContent
    
    var body: some View {
        layout
    }
    
// TODO: Re-enable tvOS support with unified hero view
#if os(tvOS)
    @State private var belowFold = false
    private let showcaseHeight = 1080 * 0.85
    
    private var layout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                heroView
                .scenePadding()
                .frame(height: showcaseHeight)
                .focusSection()
                .onScrollVisibilityChange { isVisible in
                    withAnimation {
                        belowFold = !isVisible
                    }
                }

                content
            }
            .scrollTargetLayout()
        }
        .background {
            if let url = ImageURLProvider.imageURL(for: item, type: .backdrop) {
                CachedAsyncImage(url: url, targetSize: 1500)
                    .scaledToFill()
                    .overlay {
                        Rectangle()
                            .fill(.regularMaterial)
                            .mask {
                                LinearGradient(
                                    stops: [
                                        .init(color: .white, location: 0),
                                        .init(color: .white.opacity(belowFold ? 1 : 0.7), location: 0.5),
                                        .init(color: .white.opacity(belowFold ? 1 : 0), location: 1)
                                    ],
                                    startPoint: .bottomLeading, endPoint: .topTrailing
                                )
                            }
                    }
                    .ignoresSafeArea()
            }
        }
        .scrollTargetBehavior(
            FoldSnappingScrollTargetBehavior(
                aboveFold: !belowFold, showcaseHeight: showcaseHeight)
        )
        .scrollClipDisabled()
        .toolbar(.hidden, for: .navigationBar)
    }
#else
    private var layout: some View {
        ScrollView {
            VStack {
                heroView
                
                content
            }
            .scenePadding(.bottom)
        }
        .ignoresSafeArea(edges: .top)
        .toolbarTitleDisplayMode(.inline)
        .scrollEdgeEffectHidden(true, for: .top)
    }
#endif
}
