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
    
    private var layout: some View {
        GeometryReader { geo in
            let showcaseHeight = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom

            ScrollView {
                VStack(alignment: .leading, spacing: 80) {
                    heroView
                        .padding(60)
                        .frame(height: showcaseHeight)
                        .focusSection()
                        .overlay(alignment: .bottom) {
                            if !belowFold {
                                VStack(alignment: .center) {
                                    Text("More Details")
                                    Image(systemName: "chevron.compact.down")
                                }
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.bottom)
                            }
                        }
                        .onScrollVisibilityChange { isVisible in
                            withAnimation {
                                belowFold = !isVisible
                            }
                        }
                    
                    // TODO: must have a cleaner way to do this
                    if belowFold {
                        DetailLogoOverlayView(item: item)
                            .padding(.bottom, -100)
                            .padding(.top, -60)
                    }
                    
                    content
                        .padding(40)
                }
                .scrollTargetLayout()
            }
            .background {
                if let url = ImageURLProvider.imageURL(for: item, type: .backdrop) {
                    CachedAsyncImage(url: url, targetSize: 1000)
                        .scaledToFill()
                        .mask {
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .black, location: 0),
                                    .init(color: .black, location: 0.4),
                                    .init(color: .black.opacity(0.05), location: 1.0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
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
            .ignoresSafeArea()
            .scrollTargetBehavior(
                FoldSnappingScrollTargetBehavior(
                    aboveFold: !belowFold, showcaseHeight: showcaseHeight)
            )
            .scrollClipDisabled()
            .toolbar(.hidden, for: .navigationBar)
        }
    }
#else
    @State var showScrollEffect = false
    
    private var layout: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroView
                    .onScrollVisibilityChange { isVisible in
                        showScrollEffect = isVisible
                    }
                
                content
            }
            .scenePadding(.bottom)
        }
        .ignoresSafeArea(edges: .top)
        .toolbarTitleDisplayMode(.inline)
        .scrollEdgeEffectHidden(showScrollEffect, for: .top)
    }
#endif
}
