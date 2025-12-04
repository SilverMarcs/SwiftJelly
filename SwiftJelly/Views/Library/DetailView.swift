import SwiftUI
import SwiftMediaViewer
import JellyfinAPI

struct DetailView<Content: View, ItemDetailContent: View>: View {
#if !os(tvOS)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    private var logoAlignment: HorizontalAlignment = .center
    private var logoContainerAlignment: Alignment = .center
    private var logoWidth: CGFloat = 300
    private var logoHeight: CGFloat = 100
    private var useCompactLayout: Bool { horizontalSizeClass == .compact }
    private var coverAlignment: HorizontalAlignment { horizontalSizeClass == .compact ? .leading : .center }
#else
    private var logoAlignment: HorizontalAlignment = .leading
    private var logoContainerAlignment: Alignment = .leading
    private var useCompactLayout: Bool = false
    private var logoWidth: CGFloat = 450
    private var logoHeight: CGFloat = 300
    private var coverAlignment: HorizontalAlignment = .leading
#endif

    @State private var item: BaseItemDto
    @State private var isLoading = false
    @State private var scrollOffset: CGFloat = 0
    @State private var belowFold = false

    let action: () async -> Void
    let content: Content
    let itemDetailContent: ItemDetailContent
    
    init(
        item: BaseItemDto,
        action: @escaping () async -> Void,
        @ViewBuilder content: () -> Content,
        @ViewBuilder itemDetailContent: () -> ItemDetailContent
    ) {
        self._item = State(initialValue: item)
        self.action = action
        self.content = content()
        self.itemDetailContent = itemDetailContent()
    }
    
    private var backdropHeight: CGFloat {
        useCompactLayout ? 450 : 450
    }

    var body: some View {
        #if os(tvOS)
        tvOSLayout
        #else
        standardLayout
        #endif
    }
    
    let bottomGradient = LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .white, location: 0),
                .init(color: .white.opacity(1), location: 0.3),
                .init(color: .white.opacity(0), location: 0.6)
            ]),
            startPoint: .bottom,
            endPoint: .top
        )
    
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
            .frame(maxWidth: .infinity, alignment: logoContainerAlignment)

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
    private var tvOSLayout: some View {
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
            .environment(\.refresh, action)
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
    
    private var standardLayout: some View {
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
                                bottomGradient
                            }
                    }
                    #if !os(tvOS)
                    .backgroundExtensionEffect()
                    .stretchy()
                    #endif
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
        #if !os(tvOS)
        .refreshable { await action() }
        #endif
        .ignoresSafeArea(edges: .top)
        .navigationTitle("")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                FavoriteButton(item: item)
            }
            #if os(macOS)
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        isLoading = true
                        await action()
                        isLoading = false
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .keyboardShortcut("r")
            }
            #endif
        }
        .environment(\.refresh, action)
    }
    
    #endif
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
