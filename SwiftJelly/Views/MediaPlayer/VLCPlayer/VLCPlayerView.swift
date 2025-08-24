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
    @State private var sessionManager: PlaybackSessionManager?
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
        
        // Only create session manager for Jellyfin items
        if let jellyfinItem = mediaItem.jellyfinItem {
            self._sessionManager = State(initialValue: PlaybackSessionManager(item: jellyfinItem))
        } else {
            self._sessionManager = State(initialValue: nil)
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
                let seconds = Int(duration.components.seconds)
                let totalDuration = info.length / 1000
                playbackState.updatePosition(seconds: seconds, totalDuration: totalDuration)
                updateSystemMediaPlaybackState()
                if !hasLoadedEmbeddedSubs {
                    subtitleManager.loadSubtitlesFromVLC(tracks: info.subtitleTracks)
                    hasLoadedEmbeddedSubs = true
                }
            }
            .onAppear {
                setupSystemMediaControls()
                #if os(iOS)
                OrientationManager.shared.lockOrientation(.landscape, andRotateTo: .landscapeRight)
                #endif
            }
            .preferredColorScheme(.dark)
            .navigationTitle(mediaItem.name ?? "Media Player")
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
            .background(.black, ignoresSafeAreaEdges: .all)
            .onDisappear {
                cleanup()
                #if os(iOS)
                OrientationManager.shared.lockOrientation(.all)
                #endif
            }
            .preferredColorScheme(.dark)
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
    
    private func handleStateChange(_ state: VLCVideoPlayer.State) {
        let wasPlaying = playbackState.isPlaying
        playbackState.updatePlayingState(state == .playing)
        
        // Update system media controls
        updateSystemMediaPlaybackState()
        
        // Only handle Jellyfin session management for Jellyfin items
        guard let sessionManager = sessionManager else { return }
        
        // Send start report when playback begins
        if !sessionManager.hasSentStart && state == .playing {
            sessionManager.startPlayback(at: playbackState.currentSeconds)
        }
        
        // Handle pause/resume
        if sessionManager.hasSentStart {
            if wasPlaying && state == .paused {
                sessionManager.pausePlayback(at: playbackState.currentSeconds)
            } else if !wasPlaying && state == .playing {
                sessionManager.resumePlayback(at: playbackState.currentSeconds)
            }
        }
        
        // Handle stop/end
        if state == .stopped || state == .ended {
            sessionManager.stopPlayback(at: playbackState.currentSeconds)
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
        
        // Set initial media info
        updateSystemMediaInfo()
    }
    
    private func updateSystemMediaInfo() {
        let title = mediaItem.name ?? "Unknown Title"
        var artist = ""
        var albumTitle: String? = nil
        var duration: Double = 0
        
        // Get metadata based on media type
        switch mediaItem {
        case .jellyfin(let item):
            artist = item.seriesName ?? item.albumArtist ?? ""
            if let season = item.parentIndexNumber, let episode = item.indexNumber {
                albumTitle = "S\(season)E\(episode)"
            }
            duration = Double(item.runTimeTicks ?? 0) / 10_000_000
        case .local(let file):
            artist = "Local Media"
            duration = file.duration ?? 0
        }
        
        Task {
            var artwork: MPMediaItemArtwork? = nil
            
            // Try to load artwork if available (only for Jellyfin items)
            if case .jellyfin(let item) = mediaItem,
               let imageURL = ImageURLProvider.landscapeImageURL(for: item) {
                artwork = await loadArtwork(from: imageURL)
            }
            
            // TODO: we are passing too much no need so much
            SystemMediaController.shared.updateNowPlayingInfo(
                title: title,
                artist: artist,
                albumTitle: albumTitle,
                artwork: artwork,
                duration: duration,
                currentTime: Double(playbackState.currentSeconds),
                playbackRate: playbackState.isPlaying ? 1.0 : 0.0
            )
        }
    }
    
    private func loadArtwork(from url: URL) async -> MPMediaItemArtwork? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            #if os(macOS)
            guard let image = NSImage(data: data) else { return nil }
            #else
            guard let image = UIImage(data: data) else { return nil }
            #endif
            return SystemMediaController.shared.createArtwork(from: image)
        } catch {
            print("Failed to load artwork: \(error)")
            return nil
        }
    }
    
    private func updateSystemMediaPlaybackState() {
        SystemMediaController.shared.updatePlaybackState(
            isPlaying: playbackState.isPlaying,
            currentTime: Double(playbackState.currentSeconds)
        )
    }
    
    func cleanup() {
        proxy.stop()
        sessionManager?.stopPlayback(at: playbackState.currentSeconds)
        SystemMediaController.shared.clearNowPlayingInfo()
        if let handler = RefreshHandlerContainer.shared.refresh {
            Task { await handler() }
        }
    }
}
