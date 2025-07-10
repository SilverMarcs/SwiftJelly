import SwiftUI
import JellyfinAPI

struct PlayMediaButton<Label: View>: View {
    let item: BaseItemDto
    let label: () -> Label
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif
    @State private var showPlayer = false

    var body: some View {
        Button {
            #if os(macOS)
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
        }
        #endif
    }
}
