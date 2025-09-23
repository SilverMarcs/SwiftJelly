import SwiftUI
import JellyfinAPI

struct PlayMediaButton<Label: View>: View {
    @Environment(\.refresh) var refresh
    
    let item: MediaItem
    let label: Label
    let onPlaybackFinished: (()->Void)?
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    #endif
    @State private var showPlayer = false
    
    init(item: BaseItemDto, onPlaybackFinished: (()->Void)? = nil, @ViewBuilder label: () -> Label) {
        self.item = MediaItem.jellyfin(item)
        self.label = label()
        self.onPlaybackFinished = onPlaybackFinished
    }
    
    init(item: LocalMediaFile, onPlaybackFinished: (()->Void)? = nil, @ViewBuilder label: () -> Label) {
        self.item = MediaItem.local(item)
        self.label = label()
        self.onPlaybackFinished = onPlaybackFinished
    }

    var body: some View {
        Button {
            // Provide a refresh closure for existing player cleanup paths
            RefreshHandlerContainer.shared.refresh = {
                await refresh()
                if let cb = onPlaybackFinished { cb() }
            }
            #if os(macOS)
            dismissWindow(id: "media-player") // ensure we close any open players first
            openWindow(id: "media-player", value: item)
            #else
            showPlayer = true
            #endif
        } label: { label }
        #if !os(macOS)
        .fullScreenCover(isPresented: $showPlayer, onDismiss: {
            Task { await refresh(); onPlaybackFinished?() }
        }) {
            UniversalMediaPlayer(mediaItem: item)
                .environment(\.refresh, refresh)
        }
        #endif
    }
}
