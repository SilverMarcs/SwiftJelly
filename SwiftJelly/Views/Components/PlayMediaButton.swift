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
    
    var body: some View {
        Button {
            if item.id == nil {
               return
            }
            
            RefreshHandlerContainer.shared.refresh = {
                await refresh()
            }
            #if os(macOS)
            dismissWindow(id: "media-player")
            openWindow(id: "media-player", value: item)
            #else
            showPlayer = true
            #endif
        } label: {
            label
        }
        #if !os(macOS)
        .fullScreenCover(isPresented: $showPlayer) {
            #if os(tvOS)
            AVMediaPlayerViewTVOS(item: item)
                .ignoresSafeArea()
            #else
            AVMediaPlayerViewIOS(item: item)
                .ignoresSafeArea()
                .tint(.primary)
            #endif
        }
        #endif
    }
}
