import SwiftUI
import SwiftMediaViewer
import JellyfinAPI

struct DetailView<Content: View, ItemDetailContent: View>: View {
    @Environment(\.refresh) private var refresh

    let item: BaseItemDto
    @ViewBuilder let content: Content
    @ViewBuilder let itemDetailContent: ItemDetailContent
    
    @State private var isLoading = false

    var body: some View {
        layout
            .overlay {
                if isLoading {
                    UniversalProgressView()
                }
            }
    }
    
#if os(tvOS)
    @State private var belowFold = false
    private let showcaseHeight = 1080 * 0.85
    
    private var layout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                CoverOverlayView(item: item) {
                    itemDetailContent
                }
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
                backdropSection
                
                content
            }
            .scenePadding(.bottom)
        }
        .refreshable { await refresh() }
        .ignoresSafeArea(edges: .top)
        .toolbarTitleDisplayMode(.inline)
        #if os(macOS)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        isLoading = true
                        await refresh()
                        isLoading = false
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .keyboardShortcut("r")
            }
        }
        #endif
    }
    
    private var backdropSection: some View {
        CachedAsyncImage(
            url: ImageURLProvider.imageURL(for: item, type: .backdrop),
            targetSize: 1500
        )
        .scaledToFill()
        .frame(height: 480)
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
        .overlay(alignment: .bottomLeading) {
            CoverOverlayView(item: item) {
                itemDetailContent
            }
            .padding(.bottom, 20)
        }
        .stretchy()
        .environment(\.colorScheme, .dark)
    }
#endif
}
