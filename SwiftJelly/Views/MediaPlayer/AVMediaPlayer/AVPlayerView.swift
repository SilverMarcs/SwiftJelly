import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerView: View {
    let mediaItem: MediaItem
    let player: AVPlayer
    let startTimeSeconds: Int
    
    init(mediaItem: MediaItem) {
        self.mediaItem = mediaItem
        self.startTimeSeconds = mediaItem.startTimeSeconds
        self.player = AVPlayer(url: mediaItem.url)
    }

    var body: some View {
        #if os(macOS)
        AVPlayerMac(startTimeSeconds: startTimeSeconds, player: player)
            .ignoresSafeArea()
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
            .aspectRatio(16/9, contentMode: .fit)
            .gesture(WindowDragGesture())
            .navigationTitle(mediaItem.name ?? "Media Player")
            .onDisappear {
                cleanup()
            }
//            .task {
//                if let mediaPlayerWindow = NSApplication.shared.windows.first(where: { $0.title == mediaItem.name ?? "Media Player" }) {
//                    mediaPlayerWindow.standardWindowButton(.zoomButton)?.isEnabled = false
//                    await MainActor.run {
//                        mediaPlayerWindow.title = mediaItem.name ?? "Media Player"
//                    }
//                }
//            }
        #else
        AVPlayerIos(startTimeSeconds: startTimeSeconds, player: player)
            .ignoresSafeArea()
            .onDisappear {
                cleanup()
            }
        #endif
    }
    
    func cleanup() {
        let reporter: PlaybackReporterProtocol
        
        switch mediaItem {
        case .jellyfin(let item):
            reporter = JellyfinPlaybackReporter(item: item)
        case .local(let file):
            reporter = LocalPlaybackReporter(file: file)
        }
        
        guard let time = player.currentItem?.currentTime(), time.isValid else { return }
        
        print("time", time)

        reporter.reportStop(positionSeconds: Int(time.seconds))
        player.pause()
        
        if let handler = RefreshHandlerContainer.shared.refresh {
            Task { await handler() }
        }
    }
}



//import SwiftUI
//import AVKit
//import JellyfinAPI
//
//struct AVMediaPlayerView: View {
//    let mediaItem: MediaItem
//    
//    @State var stateManager: AVPlayerStateManager
//    @Environment(LocalMediaManager.self) var localMediaManager
//    
//    let startTimeSeconds: Int
//    
//    init(mediaItem: MediaItem) {
//        self.mediaItem = mediaItem
//        self.startTimeSeconds = mediaItem.startTimeSeconds
//        self._stateManager = State(initialValue: AVPlayerStateManager(mediaItem: mediaItem))
//    }
//
//    var body: some View {
//        #if os(macOS)
//        AVPlayerMac(startTimeSeconds: startTimeSeconds, stateManager: stateManager)
//            .ignoresSafeArea()
//            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
//            .aspectRatio(16/9, contentMode: .fit)
//            .gesture(WindowDragGesture())
//            .navigationTitle(mediaItem.name ?? "Media Player")
////            .task {
////                if let mediaPlayerWindow = NSApplication.shared.windows.first(where: { $0.title == mediaItem.name ?? "Media Player" }) {
////                    mediaPlayerWindow.standardWindowButton(.zoomButton)?.isEnabled = false
////                    await MainActor.run {
////                        mediaPlayerWindow.title = mediaItem.name ?? "Media Player"
////                    }
////                }
////            }
//            .onDisappear {
//                cleanup()
//            }
//        #else
//        AVPlayerIos(startTimeSeconds: startTimeSeconds, stateManager: stateManager)
//            .ignoresSafeArea()
//            .onDisappear {
//                cleanup()
//            }
//        #endif
//    }
//    
//    func cleanup() {
//        stateManager.close()
//        if let handler = RefreshHandlerContainer.shared.refresh {
//            Task { await handler() }
//        }
//    }
//}
