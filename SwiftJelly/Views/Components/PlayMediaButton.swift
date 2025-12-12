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
    
    @State private var showPlayer = false
    
    @Namespace var transition

    var body: some View {
        Button {
            // Provide a refresh closure for existing player cleanup paths
            RefreshHandlerContainer.shared.refresh = {
                await refresh()
            }
            #if os(macOS)
            dismissWindow(id: "media-player") // ensure we close any open players first
            openWindow(id: "media-player", value: item)
            #else
            showPlayer = true
            #endif
        } label: {
            label
        }
        #if os(iOS)
        .matchedTransitionSource(id: "player-view", in: transition)
        .fullScreenCover(isPresented: $showPlayer) {
            AVMediaPlayerViewIOS(item: item)
                .navigationTransition(.zoom(sourceID: "player-view", in: transition))
        }
        #endif
    }
}
