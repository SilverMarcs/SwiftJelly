import SwiftUI
import JellyfinAPI
import VLCUI


struct MediaPlayerView: View {
    let item: BaseItemDto

    @State private var proxy: VLCVideoPlayer.Proxy = .init()
    @State private var isPlaying: Bool = false
    @State private var currentSeconds: Int = 0
    @State private var totalSeconds: Int = 1
    @State private var isSeeking: Bool = false
    @State private var seekValue: Double = 0
    @State private var playSessionID: String = ""
    @State private var hasSentStart: Bool = false
    @State private var progressReportTask: Task<Void, Never>?

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
                        currentSeconds = seconds
                        totalSeconds = playbackInfo.length / 1000

                        if !isSeeking {
                            seekValue = Double(seconds)
                        }
                    }

                    // Center controls overlay
                    HStack(spacing: 40) {
                        Button {
                            proxy.jumpBackward(5)
                        } label: {
                            Image(systemName: "gobackward.5")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.glass)

                        Button {
                            if isPlaying {
                                proxy.pause()
                            } else {
                                proxy.play()
                            }
                        } label: {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.glass)

                        Button {
                            proxy.jumpForward(5)
                        } label: {
                            Image(systemName: "goforward.5")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.glass)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack {
                    Text(formatTime(currentSeconds))
                        .font(.caption)
                        .foregroundColor(.white)
                        .monospacedDigit()

                    Slider(
                        value: Binding(
                            get: { isSeeking ? seekValue : Double(currentSeconds) },
                            set: { newValue in
                                seekValue = newValue
                            }
                        ),
                        in: 0...Double(totalSeconds),
                        onEditingChanged: { editing in
                            isSeeking = editing
                            if !editing {
                                proxy.setSeconds(.seconds(Int64(seekValue)))
                            }
                        }
                    )

                    Text(formatTime(totalSeconds))
                        .font(.caption)
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .background(.black)
            .onAppear {
                initializePlaySession()
            }
            .onDisappear {
                cleanupPlaySession()
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

    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    private func initializePlaySession() {
        playSessionID = JFAPI.shared.generatePlaySessionID()
    }

    private func cleanupPlaySession() {
        progressReportTask?.cancel()

        if hasSentStart {
            Task {
                do {
                    let positionTicks = Int64(currentSeconds) * 10_000_000
                    try await JFAPI.shared.reportPlaybackStopped(for: item, positionTicks: positionTicks, playSessionID: playSessionID)
                } catch {
                    print("Failed to send stop report: \(error)")
                }
            }
        }
    }

    private func handleStateChange(_ state: VLCVideoPlayer.State) {
        let wasPlaying = isPlaying
        isPlaying = (state == .playing)

        // Send start report when playback begins
        if !hasSentStart && state == .playing {
            hasSentStart = true
            sendStartReport()
        }

        // Handle pause/resume
        if hasSentStart {
            if wasPlaying && state == .paused {
                sendPauseReport()
            } else if !wasPlaying && state == .playing {
                sendResumeReport()
            }
        }

        // Handle stop/end
        if state == .stopped || state == .ended {
            sendStopReport()
        }
    }

    private func sendStartReport() {
        Task {
            do {
                let positionTicks = Int64(currentSeconds) * 10_000_000
                try await JFAPI.shared.reportPlaybackStart(for: item, positionTicks: positionTicks, playSessionID: playSessionID)
                startProgressReporting()
            } catch {
                print("Failed to send start report: \(error)")
            }
        }
    }

    private func sendPauseReport() {
        progressReportTask?.cancel()

        Task {
            do {
                let positionTicks = Int64(currentSeconds) * 10_000_000
                try await JFAPI.shared.reportPlaybackProgress(for: item, positionTicks: positionTicks, isPaused: true, playSessionID: playSessionID)
            } catch {
                print("Failed to send pause report: \(error)")
            }
        }
    }

    private func sendResumeReport() {
        Task {
            do {
                let positionTicks = Int64(currentSeconds) * 10_000_000
                try await JFAPI.shared.reportPlaybackProgress(for: item, positionTicks: positionTicks, isPaused: false, playSessionID: playSessionID)
                startProgressReporting()
            } catch {
                print("Failed to send resume report: \(error)")
            }
        }
    }

    private func sendStopReport() {
        progressReportTask?.cancel()

        Task {
            do {
                let positionTicks = Int64(currentSeconds) * 10_000_000
                try await JFAPI.shared.reportPlaybackStopped(for: item, positionTicks: positionTicks, playSessionID: playSessionID)
            } catch {
                print("Failed to send stop report: \(error)")
            }
        }
    }

    private func startProgressReporting() {
        progressReportTask?.cancel()

        progressReportTask = Task {
            while !Task.isCancelled && isPlaying {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds

                if !Task.isCancelled && isPlaying {
                    do {
                        let positionTicks = Int64(currentSeconds) * 10_000_000
                        try await JFAPI.shared.reportPlaybackProgress(for: item, positionTicks: positionTicks, isPaused: false, playSessionID: playSessionID)
                    } catch {
                        print("Failed to send progress report: \(error)")
                    }
                }
            }
        }
    }
}
