import SwiftUI
import JellyfinAPI
import VLCUI

struct MediaPlayerView: View {
    let item: BaseItemDto
    
    @Environment(\.dismiss) private var dismiss

    @State private var proxy: VLCVideoPlayer.Proxy = .init()
    @StateObject private var playbackState = PlaybackStateManager()
    @StateObject private var sessionManager: PlaybackSessionManager

    @State private var controlsVisible: Bool = false
    @State private var playbackInfo: VLCVideoPlayer.PlaybackInformation? = nil

    init(item: BaseItemDto) {
        self.item = item
        self._sessionManager = StateObject(wrappedValue: PlaybackSessionManager(item: item))
    }

    var body: some View {
        if let url = playbackURL {
            VLCVideoPlayer(
                configuration: .init(
                    url: url,
                    autoPlay: true,
                    startSeconds: .seconds(Int64(startTimeSeconds)),
                    subtitleSize: .absolute(24)
                )
            )
            .proxy(proxy)
            .onStateUpdated { state, info in
                handleStateChange(state)
                playbackInfo = info
            }
            .onSecondsUpdated { duration, info in
                let seconds = Int(duration.components.seconds)
                let totalDuration = info.length / 1000
                playbackState.updatePosition(seconds: seconds, totalDuration: totalDuration)
                playbackInfo = info
            }
            .contentShape(Rectangle())
            .gesture(
                TapGesture(count: 2)
                    .onEnded {
                        #if os(macOS)
                        if let window = NSApplication.shared.keyWindow {
                            window.toggleFullScreen(nil)
                        }
                        #endif
                    }
            )
            .simultaneousGesture(
                TapGesture(count: 1)
                    .onEnded {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            controlsVisible.toggle()
                        }
                    }
            )
            // Overlay for media controls (center)
            .overlay(alignment: .center) {
                if controlsVisible {
                    MediaPlayerControls(
                        playbackState: playbackState,
                        proxy: proxy
                    )
                }
            }
            // Overlay for info bar and progress bar (bottom)
            .overlay(alignment: .bottom) {
                if controlsVisible {
                    VStack {
                        MediaPlayerInfoBar(item: item, proxy: proxy, playbackInfo: playbackInfo)
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
                    .buttonStyle(.glass)
                    .padding()
                }
            }
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
                proxy.jumpBackward(5)
                return .handled
            }
            .onKeyPress(.rightArrow) {
                proxy.jumpForward(5)
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
