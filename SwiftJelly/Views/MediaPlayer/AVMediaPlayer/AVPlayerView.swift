import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerView: View {
    let mediaItem: MediaItem
    @State var player: AVPlayer
    let startTimeSeconds: Int
    let reporter: PlaybackReporterProtocol
    
    init(mediaItem: MediaItem) {
        self.mediaItem = mediaItem
        self.startTimeSeconds = mediaItem.startTimeSeconds
        self._player = State(initialValue: AVPlayer(url: mediaItem.url))
        
        switch mediaItem {
        case .jellyfin(let item):
            self.reporter = JellyfinPlaybackReporter(item: item)
        case .local(let file):
            self.reporter = LocalPlaybackReporter(file: file)
        }
        reporter.reportStart(positionSeconds: startTimeSeconds)
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
                OrientationManager.shared.lockOrientation(.all)
            }
            .onAppear {
                OrientationManager.shared.lockOrientation(.landscape, andRotateTo: .landscapeRight)
            }
        #endif
    }
    
    func cleanup() {
        guard let time = player.currentItem?.currentTime() else { return }

        let seconds = Int(time.seconds)
        
        reporter.reportPause(positionSeconds: seconds)
        reporter.reportProgress(positionSeconds: seconds, isPaused: true)
        reporter.reportStop(positionSeconds: seconds)
        player.pause()
        
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            if let handler = RefreshHandlerContainer.shared.refresh {
                await handler()
            }
        }
    }
}
