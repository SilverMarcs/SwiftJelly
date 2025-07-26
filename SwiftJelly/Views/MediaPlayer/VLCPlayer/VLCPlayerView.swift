import SwiftUI
import JellyfinAPI
import VLCUI
import MediaPlayer

#if !os(macOS)
import UIKit
#endif

struct VLCPlayerView: View {
    let item: BaseItemDto
    @State private var proxy: VLCVideoPlayer.Proxy = .init()
    @State private var playbackState = PlaybackStateManager()
    @State private var sessionManager: PlaybackSessionManager
    @State private var subtitleManager: SubtitleManager
    @State private var hasLoadedEmbeddedSubs = false
    @State private var hasSetupSystemMediaControls = false
    
    let playbackURL: URL?
    let startTimeSeconds: Int
    
    init(item: BaseItemDto) {
        self.item = item
        self.playbackURL = try? JFAPI.getPlaybackURL(for: item)
        self.startTimeSeconds = JFAPI.getStartTimeSeconds(for: item)
        self._sessionManager = State(initialValue: PlaybackSessionManager(item: item))
        self._subtitleManager = State(initialValue: SubtitleManager(item: item))
    }
    
    var body: some View {
        if let url = playbackURL {
            VLCVideoPlayer(
                configuration: .init(
                    url: url,
                    autoPlay: true,
                    startSeconds: .seconds(Int64(startTimeSeconds)),
                    subtitleSize: .absolute(24),
                    playbackChildren: subtitleManager.getPlaybackChildren()
                )
            )
            .proxy(proxy)
            .onStateUpdated { state, info in
                handleStateChange(state)
                subtitleManager.updateFromPlaybackInfo(info)
            }
            .onSecondsUpdated { duration, info in
                let seconds = Int(duration.components.seconds)
                let totalDuration = info.length / 1000
                playbackState.updatePosition(seconds: seconds, totalDuration: totalDuration)
                subtitleManager.updateFromPlaybackInfo(info)
                
                updateSystemMediaPlaybackState()
                
                if !hasLoadedEmbeddedSubs {
                    subtitleManager.loadSubtitlesFromVLC(tracks: info.subtitleTracks)
                    hasLoadedEmbeddedSubs = true
                }
            }
            .onAppear {
                subtitleManager.setVLCProxy(proxy)
                setupSystemMediaControls()
            }
            .preferredColorScheme(.dark)
            .task {
                await subtitleManager.loadExternalSubtitles()
            }
            .navigationTitle(item.name ?? "Media Player")
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
        let title = item.name ?? "Unknown Title"
        let artist = item.seriesName ?? item.albumArtist ?? ""
        var albumTitle: String? = nil
        if let season = item.parentIndexNumber, let episode = item.indexNumber {
            albumTitle = "S\(season)E\(episode)"
        }
        let duration = Double(item.runTimeTicks ?? 0) / 10_000_000 // Convert from ticks to seconds
        
        Task {
            var artwork: MPMediaItemArtwork? = nil
            
            // Try to load artwork if available
            // TODO: get this from cache servie
            if let imageURL = ImageURLProvider.landscapeImageURL(for: item) {
                artwork = await loadArtwork(from: imageURL)
            }
            
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
        sessionManager.stopPlayback(at: playbackState.currentSeconds)
        SystemMediaController.shared.clearNowPlayingInfo()
        if let handler = RefreshHandlerContainer.shared.refresh {
            Task { await handler() }
        }
    }
}
