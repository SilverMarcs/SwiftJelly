import SwiftUI
import JellyfinAPI

struct MediaLauncher: ViewModifier {
    let item: BaseItemDto
    @State private var showPlayer = false
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif

    func body(content: Content) -> some View {
        content
            .onTapGesture {
                launch()
            }
            #if !os(macOS)
            .fullScreenCover(isPresented: $showPlayer) {
                MediaPlayerView(item: item)
            }
            #endif
    }

    private func launch() {
        #if os(macOS)
        openWindow(id: "media-player", value: item)
        #else
        showPlayer = true
        #endif
    }
}

extension View {
    func mediaLauncher(for item: BaseItemDto) -> some View {
        self.modifier(MediaLauncher(item: item))
    }
}
