import SwiftUI
import JellyfinAPI
import VLCUI

struct MediaPlayerView: View {
    let item: BaseItemDto
    
    @Environment(\.dismiss) private var dismiss

    @State private var proxy: VLCVideoPlayer.Proxy = .init()
    @StateObject private var playbackState = PlaybackStateManager()
    @StateObject private var sessionManager: PlaybackSessionManager
    @StateObject private var subtitleManager: SubtitleManager

    @State private var controlsVisible: Bool = false
    @State private var playbackInfo: VLCVideoPlayer.PlaybackInformation? = nil
    @State private var hasLoadedEmbeddedSubs = false
    

    init(item: BaseItemDto) {
        self.item = item
        self._sessionManager = StateObject(wrappedValue: PlaybackSessionManager(item: item))
        self._subtitleManager = StateObject(wrappedValue: SubtitleManager(item: item))
    }

    var body: some View {
        if let url = playbackURL {
            ZStack {
                if !subtitleManager.isLoading {
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
                        playbackInfo = info
                        subtitleManager.updateFromPlaybackInfo(info)
                    }
                    .onSecondsUpdated { duration, info in
                        let seconds = Int(duration.components.seconds)
                        let totalDuration = info.length / 1000
                        playbackState.updatePosition(seconds: seconds, totalDuration: totalDuration)
                        playbackInfo = info
                        subtitleManager.updateFromPlaybackInfo(info)
                        
                        if !hasLoadedEmbeddedSubs {
                            subtitleManager.loadSubtitlesFromVLC(tracks: info.subtitleTracks)
                            hasLoadedEmbeddedSubs = true
                        }
                    }
                    .onAppear {
                        subtitleManager.setVLCProxy(proxy)
                    }
                } else {
                    ZStack {
                        Color.black
                        ProgressView("Loading subtitles...")
                            .foregroundStyle(.white)
                    }
                }
            }
            .task {
                await subtitleManager.loadExternalSubtitles()
            }
//            .aspectRatio(item.aspectRatio?.toCGFloatRatio() ?? 16/9, contentMode: .fit)
            .navigationTitle(item.name ?? "Media Player")
            .contentShape(Rectangle())
#if os(macOS)
            .gesture(
                TapGesture(count: 2)
                    .onEnded {
                        if let window = NSApplication.shared.keyWindow {
                            window.toggleFullScreen(nil)
                        }
                    }
            )
#endif
            .simultaneousGesture(
                TapGesture(count: 1)
                    .onEnded {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            controlsVisible.toggle()
                        }
                    }
            )
            .overlay {
                if controlsVisible
                {
                    Color.black.opacity(0.5)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: controlsVisible)
                        .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .center) {
                if controlsVisible {
                    MediaPlayerControls(
                        playbackState: playbackState,
                        proxy: proxy
                    )
                }
            }
            .overlay(alignment: .bottom) {
                if controlsVisible {
                    VStack {
                        MediaPlayerInfoBar(
                            item: item, 
                            proxy: proxy, 
                            playbackInfo: playbackInfo,
                            subtitleManager: subtitleManager
                        )
                        
                        MediaPlayerProgressBar(
                            playbackState: playbackState,
                            proxy: proxy
                        )
                    }
                    .padding()
                }
            }
            #if !os(macOS)
            .overlay(alignment: .topTrailing) {
                if controlsVisible {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.pla)
                    .padding()
                }
            }
            .ignoresSafeArea(edges: .vertical)
            #endif
            .background(.black)
            .onDisappear {
                sessionManager.stopPlayback(at: playbackState.currentSeconds)
            }
            .onKeyPress(.space) {
                if playbackState.isPlaying {
                    proxy.pause()
                } else {
                    proxy.play()
                }
                return .handled
            }
            .onKeyPress(.leftArrow) {
                proxy.jumpBackward(10)
                return .handled
            }
            .onKeyPress(.rightArrow) {
                proxy.jumpForward(10)
                return .handled
            }
        } else {
            Text("Unable to play this item.")
                .padding()
        }
    }

    private var playbackURL: URL? {
        try? JFAPI.shared.getPlaybackURL(for: item)
    }

    private var startTimeSeconds: Int {
        JFAPI.shared.getStartTimeSeconds(for: item)
    }

    private func handleStateChange(_ state: VLCVideoPlayer.State) {
        let wasPlaying = playbackState.isPlaying
        playbackState.updatePlayingState(state == .playing)

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

}
