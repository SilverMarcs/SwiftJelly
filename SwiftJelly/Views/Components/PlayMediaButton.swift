import SwiftUI
import JellyfinAPI

struct PlayMediaButton<Label: View>: View {
    @Environment(\.refresh) var refresh
    
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    #endif
        
    let item: BaseItemDto
    @ViewBuilder let label: Label
    
    var body: some View {
        Button {
            guard item.id != nil else { return }
            
            #if os(macOS)
            dismissWindow(id: "media-player")
            openWindow(id: "media-player")
            #endif

            PlaybackManager.shared.startPlayback(for: item) {
                await refresh()
            }
        } label: {
            label
        }
    }
}
