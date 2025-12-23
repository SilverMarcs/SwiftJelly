import SwiftUI
import JellyfinAPI

struct PlayMediaButton<Label: View>: View {
    @Environment(\.refresh) var refresh
    @Namespace var transition
    
    let item: BaseItemDto
    let label: Label

    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    #endif
    
    @State private var showPlayer = false
    
    init(item: BaseItemDto, @ViewBuilder label: () -> Label) {
        self.item = item
        self.label = label()
    }

    var body: some View {
        Button {
            if item.id == nil {
                return
            }

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
        .optionalMatchedTransitionSource(id: "player-view", in: transition)
        
        #if !os(macOS)
        .fullScreenCover(isPresented: $showPlayer) {
            AVMediaPlayerViewIOS(item: item)
            #if os(iOS)
                .navigationTransition(.zoom(sourceID: "player-view", in: transition))
            #endif
        }
        #endif
    }
}
