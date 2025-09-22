import SwiftUI
import JellyfinAPI
import VLCUI
import MediaPlayer

#if !os(macOS)
import UIKit
#endif

struct VLCPlayerView: View {
    @Environment(LocalMediaManager.self) var localMediaManager
    let mediaItem: MediaItem
    
    private var proxy: VLCVideoPlayer.Proxy
    private var playbackState = PlaybackStateManager()
    private var subtitleManager: SubtitleManager
    
    let playbackURL: URL?
    let startTimeSeconds: Int
    let reporter: PlaybackReporterProtocol

    init(mediaItem: MediaItem) {
        self.mediaItem = mediaItem
        self.playbackURL = mediaItem.url
        self.startTimeSeconds = mediaItem.startTimeSeconds
        
        let vlcProxy = VLCVideoPlayer.Proxy()
        self.proxy = vlcProxy
        
        subtitleManager = SubtitleManager(vlcProxy: vlcProxy)
        
        switch mediaItem {
        case .jellyfin(let item):
            self.reporter = JellyfinPlaybackReporter(item: item)
        case .local(let file):
            self.reporter = LocalPlaybackReporter(file: file)
        }
        reporter.reportStart(positionSeconds: startTimeSeconds)
    }
    
    var body: some View {
        if let url = playbackURL {
            VLCVideoPlayer(
                configuration: .init(
                    url: url,
                    autoPlay: true,
                    startSeconds: .seconds(Int64(startTimeSeconds)),
                    subtitleSize: .absolute(24),
                )
            )
            .proxy(proxy)
//            .onStateUpdated { state, info in
//                handleStateChange(state)
//            }
            .onSecondsUpdated { duration, info in
                handleTicks(duration: duration, info: info)
            }
            .onAppear {
                subtitleManager.primeServerStreams(from: mediaItem) // load metadata only; don’t add yet
//                setupSystemMediaControls()
                #if os(iOS)
                OrientationManager.shared.lockOrientation(.landscape, andRotateTo: .landscapeRight)
                #endif
            }
            .onDisappear {
                cleanup()
                #if os(iOS)
                OrientationManager.shared.lockOrientation(.all)
                #endif
            }
            .navigationTitle(mediaItem.name ?? "Media Player")
            .background(.black, ignoresSafeAreaEdges: .all)
            .preferredColorScheme(.dark)
            #if os(macOS)
            .gesture(WindowDragGesture())
            .aspectRatio(16/9, contentMode: .fill)
            .ignoresSafeArea()
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
            .onTapGesture(count: 2) {
                if let window = NSApplication.shared.keyWindow {
                    window.toggleFullScreen(nil)
                }
            }
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Toggle FullScreen") {
                        guard let window = NSApplication.shared.keyWindow else { return }
                       window.toggleFullScreen(nil)
                    }
                    .keyboardShortcut("F")
                }
            }
            #endif
            .mediaPlayerKeyboardShortcuts(
                playbackState: playbackState,
                proxy: proxy
            )
            .mediaPlayerOverlays(
                proxy: proxy,
                playbackState: playbackState,
                subtitleManager: subtitleManager,
            )
        }
    }
    
    private func handleTicks(duration: Duration, info: VLCVideoPlayer.PlaybackInformation) {
        let seconds = Int(duration.components.seconds)
        let totalDuration = info.length / 1000
        playbackState.updatePosition(seconds: seconds, totalDuration: totalDuration)

        subtitleManager.onVLCTracksUpdated(info.subtitleTracks)

        // Periodic progress (throttled internally to ~10s by JellyfinPlaybackReporter)
        reporter.reportProgress(positionSeconds: seconds, isPaused: !playbackState.isPlaying)

        if case .local(let file) = mediaItem, file.durationSeconds == nil, totalDuration > 0 {
            let updatedFile = LocalMediaFile(
                url: file.url,
                name: file.name,
                durationSeconds: totalDuration
            )
            localMediaManager.updateRecentFile(updatedFile)
        }
    }
    
    private func cleanup() {
        proxy.stop()
        
        reporter.reportStop(positionSeconds: playbackState.currentSeconds)
        
        // Stop accessing security-scoped resource for local files
        #if os(macOS)
        if case .local(let file) = mediaItem {
            file.stopAccessingSecurityScopedResource()
        }
        #endif
        
        // Add a small delay to allow server to process the stop report before refreshing
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 1 second delay
            if let handler = RefreshHandlerContainer.shared.refresh {
                await handler()
            }
        }
    }
}
