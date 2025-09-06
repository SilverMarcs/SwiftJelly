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
    
    @State private var proxy: VLCVideoPlayer.Proxy
    @State private var playbackState = PlaybackStateManager()
    @State private var subtitleManager: SubtitleManager
    
    @State private var hasLoadedEmbeddedSubs = false
    @State private var hasSetupSystemMediaControls = false
    
    let playbackURL: URL?
    let startTimeSeconds: Int
    let reporter: PlaybackReporterProtocol
    
    init(mediaItem: MediaItem) {
        self.mediaItem = mediaItem
        self.playbackURL = mediaItem.url
        self.startTimeSeconds = mediaItem.startTimeSeconds
        
        let vlcProxy = VLCVideoPlayer.Proxy()
        self._proxy = State(initialValue: vlcProxy)
        
        // Initialize subtitle manager with the proxy
        self._subtitleManager = State(initialValue: SubtitleManager(vlcProxy: vlcProxy))
        
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
            .onStateUpdated { state, info in
                handleStateChange(state)
            }
            .onSecondsUpdated { duration, info in
                handleTicks(duration: duration, info: info)
            }
            .onAppear {
                setupSystemMediaControls()
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
            .preferredColorScheme(.dark)
            .navigationTitle(mediaItem.name ?? "Media Player")
            .background(.black, ignoresSafeAreaEdges: .all)
            .preferredColorScheme(.dark)
            #if os(macOS)
            .gesture(WindowDragGesture())
            .aspectRatio(16/9, contentMode: .fill)
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
            .onTapGesture(count: 2) {
                if let window = NSApplication.shared.keyWindow {
                    window.toggleFullScreen(nil)
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
        SystemMediaController.shared.updatePlaybackState(
            isPlaying: playbackState.isPlaying,
            currentTime: Double(playbackState.currentSeconds)
        )
        
        if !hasLoadedEmbeddedSubs {
            subtitleManager.loadSubtitlesFromVLC(tracks: info.subtitleTracks)
            hasLoadedEmbeddedSubs = true
        }
        
        // Update local media file duration if not already set
        if case .local(let file) = mediaItem, file.durationSeconds == nil, totalDuration > 0 {
            let updatedFile = LocalMediaFile(
                url: file.url,
                name: file.name,
                durationSeconds: totalDuration
            )
            localMediaManager.updateRecentFile(updatedFile)
        }
    }
    
    private func handleStateChange(_ state: VLCVideoPlayer.State) {
        playbackState.updatePlayingState(state == .playing)
        
        // Update system media controls
        SystemMediaController.shared.updatePlaybackState(
            isPlaying: playbackState.isPlaying,
            currentTime: Double(playbackState.currentSeconds)
        )
    }
    
    private func setupSystemMediaControls() {
        guard !hasSetupSystemMediaControls else { return }
        hasSetupSystemMediaControls = true
        
        SystemMediaController.shared.setHandlers(
            playPause: {
                if playbackState.isPlaying {
                    proxy.pause()
                } else {
                    proxy.play()
                }
            },
            seek: { seconds in
                if seconds > 0 {
                    proxy.jumpForward(Int(seconds))
                } else {
                    proxy.jumpBackward(Int(abs(seconds)))
                }
            },
            changePlaybackPosition: { position in
                proxy.setSeconds(.seconds(position))
            }
        )
        
        // Set initial media info via SystemMediaController
        Task {
            await SystemMediaController.shared.updateNowPlayingInfo(for: mediaItem, playbackState: playbackState)
        }
    }

    private func cleanup() {
        proxy.stop()
        
        reporter.reportStop(positionSeconds: playbackState.currentSeconds)
        
        // Add a small delay to allow server to process the stop report before refreshing
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 1 second delay
            if let handler = RefreshHandlerContainer.shared.refresh {
                await handler()
            }
        }
        
        SystemMediaController.shared.clearNowPlayingInfo()
    }
}
