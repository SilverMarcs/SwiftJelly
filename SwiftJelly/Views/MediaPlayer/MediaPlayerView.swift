import SwiftUI
import JellyfinAPI
import VLCUI

struct MediaPlayerView: View {
    let item: BaseItemDto

    @State private var proxy: VLCVideoPlayer.Proxy = .init()
    @StateObject private var playbackState = PlaybackStateManager()
    @StateObject private var sessionManager: PlaybackSessionManager

    init(item: BaseItemDto) {
        self.item = item
        self._sessionManager = StateObject(wrappedValue: PlaybackSessionManager(item: item))
    }

    var body: some View {
        if let url = playbackURL {
            VStack(spacing: 0) {
                ZStack {
                    VLCVideoPlayer(
                        configuration: .init(
                            url: url,
                            autoPlay: true,
                            startSeconds: .seconds(Int64(startTimeSeconds))
                        )
                    )
                    .proxy(proxy)
                    .onStateUpdated { state, _ in
                        handleStateChange(state)
                    }
                    .onSecondsUpdated { duration, playbackInfo in
                        let seconds = Int(duration.components.seconds)
                        let totalDuration = playbackInfo.length / 1000
                        playbackState.updatePosition(seconds: seconds, totalDuration: totalDuration)

                        // Report progress periodically during playback
                        if playbackState.isPlaying {
                            sessionManager.reportProgress(currentSeconds: seconds)
                        }
                    }

                    // Center controls overlay
                    MediaPlayerControls(
                        isPlaying: playbackState.isPlaying,
                        onPlayPause: {
                            if playbackState.isPlaying {
                                proxy.pause()
                            } else {
                                proxy.play()
                            }
                        },
                        onSeekBackward: {
                            proxy.jumpBackward(5)
                        },
                        onSeekForward: {
                            proxy.jumpForward(5)
                        }
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                MediaPlayerProgressBar(
                    currentSeconds: playbackState.currentSeconds,
                    totalSeconds: playbackState.totalSeconds,
                    seekValue: playbackState.seekValue,
                    isSeeking: playbackState.isSeeking,
                    onSeekValueChanged: { newValue in
                        playbackState.startSeeking(to: newValue)
                    },
                    onSeekingChanged: { editing in
                        if editing {
                            // User started seeking
                        } else {
                            // User finished seeking
                            let seekPosition = playbackState.endSeeking()
                            proxy.setSeconds(.seconds(Int64(seekPosition)))
                        }
                    }
                )
            }
            .background(.black)
            .onDisappear {
                sessionManager.stopPlayback(at: playbackState.currentSeconds)
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
