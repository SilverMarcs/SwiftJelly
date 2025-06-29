
import SwiftUI
import JellyfinAPI
import VLCUI


struct MediaPlayerView: View {
    let item: BaseItemDto

    // State that was previously in MediaPlayerViewModel
    @State private var playbackPosition: Int = 0
    @State private var duration: Int = 1
    @State private var isPlaying: Bool = false
    @State private var isLoading: Bool = false
    @State private var subtitleTracks: [MediaTrack] = []
    @State private var selectedSubtitleIndex: Int? = nil

    // VLC player proxy and other state
    @State private var proxy: VLCVideoPlayer.Proxy = .init()
    @State private var playbackInfo: VLCVideoPlayer.PlaybackInformation? = nil
    @State private var isSeeking = false
    @State private var seekValue: Double = 0

    private let api = JFAPI.shared

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if let url = playbackURL {
                    VLCVideoPlayer(
                        configuration: .init(
                            url: url,
                            autoPlay: true,
                            startSeconds: .seconds(Int64(startTimeSeconds)),
                            subtitleIndex: selectedSubtitleIndex.map { .absolute($0) } ?? .auto
                        )
                    )
                    .proxy(proxy)
                    .onTicksUpdated { ticks, info in
                        let seconds = ticks / 1000
                        playbackPosition = seconds
                        duration = info.length / 1000
                        playbackInfo = info
                        if !isSeeking {
                            seekValue = Double(seconds)
                        }
                        subtitleTracks = info.subtitleTracks
                    }
                    .onStateUpdated { state, _ in
                        isPlaying = (state == .playing)
                    }
                } else {
                    Text("Unable to play this item.")
                        .padding()
                }

                // Center controls
                if playbackInfo != nil {
                    HStack(spacing: 40) {
                        Button {
                            proxy.jumpBackward(5)
                        } label: {
                            Image(systemName: "gobackward.5")
                                .font(.system(size: 32))
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
                        }
                        .buttonStyle(.glass)

                        Button {
                            proxy.jumpForward(5)
                        } label: {
                            Image(systemName: "goforward.5")
                                .font(.system(size: 32))
                        }
                        .buttonStyle(.glass)
                    }
                }
            }

            // Playback slider and subtitle picker
            HStack {
                Slider(value: Binding(
                    get: { isSeeking ? seekValue : Double(playbackPosition) },
                    set: { newValue in
                        seekValue = newValue
                    }
                ), in: 0...Double(duration), onEditingChanged: { editing in
                    isSeeking = editing
                    if !editing {
                        proxy.setSeconds(.seconds(Int(seekValue)))
                    }
                })
                .padding(.horizontal)

                // Subtitle picker
                if !subtitleTracks.isEmpty {
                    Picker("Subtitles", selection: Binding(
                        get: { selectedSubtitleIndex ?? -1 },
                        set: { idx in
                            if idx >= 0 {
                                selectedSubtitleIndex = idx
                                proxy.setSubtitleTrack(.absolute(idx))
                            }
                        }
                    )) {
                        Text("Subtitles Off").tag(-1)
                        ForEach(subtitleTracks, id: \ .index) { track in
                            Text(track.title).tag(track.index)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .padding(.trailing)
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color.black)
    }

    private var playbackURL: URL? {
        try? api.getPlaybackURL(for: item)
    }

    private var startTimeSeconds: Int {
        api.getStartTimeSeconds(for: item)
    }
}
