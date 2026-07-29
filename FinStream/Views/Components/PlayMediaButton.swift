import SwiftUI
import JellyfinAPI

struct PlayMediaButton<Label: View>: View {
    @Environment(\.refresh) var refresh
    
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    #endif

    #if os(iOS)
    @Environment(\.playerZoomNamespace) private var playerZoomNamespace
    /// A stable identifier unique to this button, used as the source of the
    /// zoom transition into the full screen player.
    @State private var zoomID = UUID().uuidString
    #endif
        
    let item: BaseItemDto?
    @ViewBuilder let label: Label
    
    var body: some View {
        Button {
            guard item?.id != nil else { return }
            
            #if os(macOS)
            dismissWindow(id: "media-player")
            openWindow(id: "media-player")
            #endif

            #if os(iOS)
            PlaybackManager.shared.zoomSourceID = zoomID
            #endif

            PlaybackManager.shared.startPlayback(for: item!) {
                await refresh()
            }
        } label: {
            label
        }
        #if os(iOS)
        .zoomTransitionSource(id: zoomID, in: playerZoomNamespace)
        #endif
    }
}
