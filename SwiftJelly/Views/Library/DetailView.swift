import SwiftUI
import SwiftMediaViewer
import JellyfinAPI

struct DetailView<Content: View, ItemDetailContent: View>: View {
    // need to test this
    @Environment(\.refresh) private var refresh
    #if !os(tvOS)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    #endif

    let item: BaseItemDto
    @ViewBuilder let content: Content
    @ViewBuilder let itemDetailContent: ItemDetailContent
    
    @State private var isLoading = false

    var body: some View {
        layout
    }
    
    private var coverOverlay: some View {
        VStack(alignment: coverAlignment, spacing: 5) {
            Spacer()

            VStack(alignment: logoAlignment, spacing: 12) {
                if let url = ImageURLProvider.imageURL(for: item, type: .logo) {
                    CachedAsyncImage(url: url, targetSize: 450, opaque: false)
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
                    .padding(.top, 10)
            }
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: Alignment(horizontal: logoAlignment, vertical: .center))

            if let overview = item.overview {
                Text(overview)
                    .font(.callout)
                    .opacity(0.7)
                    .lineLimit(4)
                    .frame(maxWidth: 800, alignment: .leading)
            }
            
            AttributesView(item: item)
        }
        .ignoresSafeArea()
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
    }
    
#if os(tvOS)
    @State private var belowFold = false
    
    private var layout: some View {
        GeometryReader { geo in
            let showcaseHeight = geo.size.height

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 26) {
                    coverOverlay
                        .padding(40)
                        .frame(maxWidth: 900, alignment: .leading)
                        .frame(height: geo.size.height + geo.safeAreaInsets.top)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .focusSection()
                        .onScrollVisibilityChange { isVisible in
                            withAnimation {
                                belowFold = !isVisible
                            }
                        }

                    Section {
                        content
                    }
                }
                .scrollTargetLayout()
            }
            .background {
                if let url = ImageURLProvider.imageURL(for: item, type: .backdrop) ?? ImageURLProvider.imageURL(for: item, type: .primary) {
                    CachedAsyncImage(url: url, targetSize: 2880)
                        .aspectRatio(contentMode: .fill)
                        .overlay {
                            Rectangle()
                                .fill(.regularMaterial)
                                .mask {
                                    maskView
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
            .frame(maxHeight: .infinity, alignment: .top)
            .overlay {
                if isLoading {
                    UniversalProgressView()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .environment(\.refresh, refresh)
        }
    }
    
    var maskView: some View {
        LinearGradient(
            stops: [
                .init(color: .white, location: 0),
                .init(color: .white.opacity(belowFold ? 1 : 0.7), location: 0.5),
                .init(color: .white.opacity(belowFold ? 1 : 0), location: 1)
            ],
            startPoint: .bottomLeading, endPoint: .topTrailing
        )
    }
#else
    private var layout: some View {
        ScrollView {
            let reflectionHeight: CGFloat = 200
            let backdrop = CachedAsyncImage(
                url: ImageURLProvider.imageURL(for: item, type: .backdrop),
                targetSize: 2880
            )

            LazyVStack(alignment: .leading) {
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
                    .overlay {
                        Rectangle()
                            .fill(.regularMaterial)
                            .mask {
                                LinearGradient(
                                    stops: [
                                        .init(color: .white, location: 0),
                                        .init(color: .white.opacity(1), location: 0.3),
                                        .init(color: .white.opacity(0), location: 0.6)
                                    ],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            }
                    }
                    .backgroundExtensionEffect()
                    .stretchy()
                    .overlay(alignment: .bottomLeading) {
                        coverOverlay
                            .padding(.bottom, 20)
                    }
                }
                .environment(\.colorScheme, .dark)
                .frame(height: backdropHeight + reflectionHeight)
            
                OverviewView(item: item)
                
                content
                    .padding(.bottom)
            }
        }
        .overlay {
            if isLoading {
                UniversalProgressView()
            }
        }
        .refreshable { await refresh() }
        .ignoresSafeArea(edges: .top)
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            #if os(macOS)
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
            #endif
        }
    }
#endif
    

    private let backdropHeight: CGFloat = 450
    
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
        300
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
        horizontalSizeClass == .compact ? .leading : .center
    #endif
    }
}
