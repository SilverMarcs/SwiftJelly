import SwiftUI
import JellyfinAPI

struct PlayMediaButton<Label: View>: View {
    @Environment(\.refresh) var refresh
    
    let item: MediaItem
    let label: Label
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    #endif
    @State private var showPlayer = false
    
    init(item: BaseItemDto, @ViewBuilder label: () -> Label) {
        self.item = MediaItem.jellyfin(item)
        self.label = label()
    }
    
    init(item: LocalMediaFile, @ViewBuilder label: () -> Label) {
        self.item = MediaItem.local(item)
        self.label = label()
    }

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
            label
        }
        #if !os(macOS)
        .fullScreenCover(isPresented: $showPlayer) {
            UniversalMediaPlayer(mediaItem: item)
                .environment(\.refresh, refresh)
        }
        #endif
    }
}
