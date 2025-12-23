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
    private var logoWidth: CGFloat = 500
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
    ) {        self._item = State(initialValue: item)
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
                        .frame(maxWidth: logoWidth, maxHeight: logoHeight, alignment: .bottom)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(item.name ?? "Unknown")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 4)
                }
                #if !os(tvOS)
                itemDetailContent
                    .padding(.top, 10)
                #endif
            }
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: logoContainerAlignment)

            if let overview = item.overview {
                Text(overview)
                    .font(.callout)
                    .opacity(0.7)
                    .lineLimit(3)
                    .frame(maxWidth: 600)
            }
            
            #if os(tvOS)
            HStack {
                itemDetailContent
                    .padding(.vertical, 30)
                
                Spacer()
                
                AttributesView(item: item)
            }
            #else
            AttributesView(item: item)
            #endif
        }
        #if os(tvOS)
        .focusSection()
        #endif
        .ignoresSafeArea()
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
#if os(tvOS)
    let maskView = LinearGradient(
        gradient: Gradient(stops: [
            .init(color: .black, location: 0),
            .init(color: .black, location: 0.4),
            .init(color: .black.opacity(0.05), location: 1.0)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )

    private var tvOSLayout: some View {
        GeometryReader { geo in
            let showcaseHeight = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    coverOverlay
                        .padding(50)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .environment(\.colorScheme, .dark)
                        .onScrollVisibilityChange { isVisible in
                            withAnimation {
                                belowFold = !isVisible
                            }
                        }
                        .frame(height: showcaseHeight)

                    content
                        .padding(80)
                }
                .scrollTargetLayout()
            }
            .background {
                if let url = ImageURLProvider.imageURL(for: item, type: .backdrop) ?? ImageURLProvider.imageURL(for: item, type: .primary) {
                    CachedAsyncImage(url: url, targetSize: 2880)
                        .aspectRatio(contentMode: .fill)
                        .mask {
                            maskView
                        }
                        .background {
                            Rectangle()
                                .fill(.black)
                        }
                        .overlay {
                            if belowFold {
                                Rectangle()
                                    .fill(.thinMaterial)
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
            .ignoresSafeArea()
            .toolbar(.hidden, for: .navigationBar)
            .environment(\.refresh, action)
        }
    }
#else
    
    private var standardLayout: some View {
        ScrollView {
            let backdrop = CachedAsyncImage(
                url: ImageURLProvider.imageURL(for: item, type: .backdrop),
                targetSize: 2880
            )

            LazyVStack(alignment: .leading) {
                ExpandedImage(image: backdrop, imageHeight: backdropHeight, stretchy: true)
                    .overlay {
                        Rectangle()
                            .fill(.regularMaterial)
                            .mask {
                                bottomGradient
                            }
                    }
                    .overlay(alignment: .bottomLeading) {
                        coverOverlay
                            .padding(.bottom, 20)
                    }
                    .environment(\.colorScheme, .dark)
                    .ignoresSafeArea(edges: .top)
            
                OverviewView(item: item)
                
                content
                    .padding(.bottom)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationTitle("")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if isLoading {
                    ProgressView()
                } else {
                    Button {
                        isLoading = true
                        
                        Task {
                            await action()
                            DispatchQueue.main.async {
                                isLoading = false
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .keyboardShortcut("r")
                }
            }

            ToolbarItem(placement: .primaryAction) {
                FavoriteButton(item: item)
            }
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
