import SwiftUI
import JellyfinAPI

struct PlayMediaButton<Label: View>: View {
    @Environment(\.refresh) var refresh
    
    let item: BaseItemDto
    let label: () -> Label
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    #endif
    @State private var showPlayer = false

    var body: some View {
        Button {
            RefreshHandlerContainer.shared.refresh = refresh
            #if os(macOS)
            dismissWindow(id: "media-player") // ensure we close any open players first
            openWindow(id: "media-player", value: item)
            #else
            showPlayer = true
            #endif
        } label: {
            label()
        }
        #if !os(macOS)
        .fullScreenCover(isPresented: $showPlayer) {
            UniversalMediaPlayerView(item: item)
                .environment(\.refresh, refresh)
        }
        #endif
    }
}

final class RefreshHandlerContainer {
    static let shared = RefreshHandlerContainer()
    private init() {}
    
    var refresh: (() async -> Void)?
}
