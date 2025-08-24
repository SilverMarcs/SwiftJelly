import SwiftUI
import JellyfinAPI
import VLCUI
import MediaPlayer

#if !os(macOS)
import UIKit
#endif

struct VLCPlayerView: View {
    let mediaItem: MediaItem
    
    @State private var proxy: VLCVideoPlayer.Proxy
    @State private var playbackState = PlaybackStateManager()
    @State private var playbackReporter: PlaybackReporterProtocol
    @State private var subtitleManager: SubtitleManager
    
    @State private var hasLoadedEmbeddedSubs = false
    @State private var hasSetupSystemMediaControls = false
    
    let playbackURL: URL?
    let startTimeSeconds: Int
    
    init(mediaItem: MediaItem) {
        self.mediaItem = mediaItem
        self.playbackURL = mediaItem.url
        self.startTimeSeconds = mediaItem.startTimeSeconds
        
        let vlcProxy = VLCVideoPlayer.Proxy()
        self._proxy = State(initialValue: vlcProxy)
        
        // Initialize subtitle manager with the proxy
        self._subtitleManager = State(initialValue: SubtitleManager(vlcProxy: vlcProxy))
        
        // Initialize appropriate playback reporter based on media type
        switch mediaItem {
        case .jellyfin(let item):
            self._playbackReporter = State(initialValue: JellyfinPlaybackReporter(item: item))
        case .local(let file):
            self._playbackReporter = State(initialValue: LocalPlaybackReporter(file: file))
        }
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
            LocalMediaManager.shared.addRecentFile(updatedFile)
        }
        
        // Send periodic progress updates
        // playbackReporter?.reportProgress(
        //     positionSeconds: playbackState.currentSeconds,
        //     isPaused: !playbackState.isPlaying
        // )
    }
    
    private func handleStateChange(_ state: VLCVideoPlayer.State) {
        let wasPlaying = playbackState.isPlaying
        playbackState.updatePlayingState(state == .playing)
        
        // Update system media controls
        SystemMediaController.shared.updatePlaybackState(
            isPlaying: playbackState.isPlaying,
            currentTime: Double(playbackState.currentSeconds)
        )
        
        // Send start report when playback begins
        if !playbackReporter.hasStarted && state == .playing {
            playbackReporter.reportStart(positionSeconds: playbackState.currentSeconds)
        }
        
        // Handle pause/resume
        if playbackReporter.hasStarted {
            if wasPlaying && state == .paused {
                playbackReporter.reportPause(positionSeconds: playbackState.currentSeconds)
            } else if !wasPlaying && state == .playing {
                playbackReporter.reportResume(positionSeconds: playbackState.currentSeconds)
            }
        }
        
        // Handle stop/end
        if state == .stopped || state == .ended {
            playbackReporter.reportStop(positionSeconds: playbackState.currentSeconds)
        }
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

    func cleanup() {
        proxy.stop()
        playbackReporter.reportStop(positionSeconds: playbackState.currentSeconds)
        SystemMediaController.shared.clearNowPlayingInfo()
        if let handler = RefreshHandlerContainer.shared.refresh {
            Task { await handler() }
        }
    }
}
