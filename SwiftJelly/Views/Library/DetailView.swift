import SwiftUI
import SwiftMediaViewer
import JellyfinAPI

struct DetailView<Content: View, ItemDetailContent: View>: View {
    #if !os(tvOS)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    #endif
    @State private var item: BaseItemDto
    @State private var isLoading = false
    @State private var scrollOffset: CGFloat = 0
    @State private var blurBackground = false
    
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
    
    private var useCompactLayout: Bool {
        #if os(tvOS)
        false
        #else
        horizontalSizeClass == .compact
        #endif
    }
    
    var body: some View {
        #if os(tvOS)
        tvOSLayout
        #else
        standardLayout
        #endif
    }
    
    let gradient = LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .white, location: 0),
                .init(color: .white.opacity(0.2), location: 0.5),
                .init(color: .white.opacity(0.1), location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    
    #if os(tvOS)
    private var tvOSLayout: some View {
        ScrollView() {
            coverOverlay
                .padding(40)
                .frame(maxWidth: 900, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .containerRelativeFrame([.vertical])
                .onScrollVisibilityChange { isVisible in
                    withAnimation {
                        blurBackground = !isVisible
                    }
                }
                .focusSection()

            content
        }
        .background {
            if let url = ImageURLProvider.imageURL(for: item, type: .backdrop) ?? ImageURLProvider.imageURL(for: item, type: .primary) {
                CachedAsyncImage(url: url, targetSize: 2880)
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .blur(radius: blurBackground ? 60 : 0)
                    .scaleEffect(1.1)
                    .mask(gradient)
                    .ignoresSafeArea()
            }
        }
        .overlay {
            if isLoading {
                UniversalProgressView()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .environment(\.refresh, action)
    }
    
    private var coverOverlay: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 480)
            
            VStack(alignment: .leading, spacing: 12) {
                if let url = ImageURLProvider.imageURL(for: item, type: .logo) {
                    CachedAsyncImage(url: url, targetSize: 450)
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 450)
                } else {
                    Text(item.name ?? "Unknown")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 4)
                }
                
                AttributesView(item: item)
                    .padding(.top, 20)
                
                if let overview = item.overview {
                    Text(overview)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(3)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
                
                itemDetailContent
                    .padding(.top, 16)
            }
            .focusSection()
        }
    }
    #endif
    
    private var standardLayout: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Group {
                    if useCompactLayout {
                        PortraitImageView(item: item)
                    } else {
                        LandscapeImageView(item: item)
                            .frame(maxHeight: 450)
                    }
                }
                #if os(macOS)
                .backgroundExtensionEffect()
                #elseif !os(tvOS)
                .stretchy()
                #endif
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 8) {
                        AttributesView(item: item)
                            .padding(.leading, 1)
                        
                        MoviePlayButton(item: item)
                            .environment(\.refresh, action)
                        
                        MarkPlayedButton(item: item)
                            .environment(\.refresh, action)
                    }
                    .padding(16)
                }
            
                OverviewView(item: item)
                
                content
            }
            .scenePadding(.bottom)
            .contentMargins(.horizontal, 18)
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
        .navigationTitle(item.name ?? "Movie")
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
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
