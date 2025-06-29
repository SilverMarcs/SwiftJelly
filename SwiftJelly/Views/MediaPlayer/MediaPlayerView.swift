
import SwiftUI
import JellyfinAPI
import VLCUI


struct MediaPlayerView: View {
    let item: BaseItemDto
    let server: Server
    let user: User
    @StateObject private var viewModel: MediaPlayerViewModel
    @State private var playbackInfo: VLCVideoPlayer.PlaybackInformation? = nil
    @State private var isSeeking = false
    @State private var seekValue: Double = 0

    init(item: BaseItemDto, server: Server, user: User) {
        _viewModel = StateObject(wrappedValue: MediaPlayerViewModel(item: item, server: server, user: user))
        self.item = item
        self.server = server
        self.user = user
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if let url = playbackURL {
                    VLCVideoPlayer(
                        configuration: .init(
                            url: url,
                            autoPlay: true,
                            startSeconds: .seconds(Int64(startTimeSeconds)),
                            subtitleIndex: viewModel.selectedSubtitleIndex.map { .absolute($0) } ?? .auto
                        )
                    )
                    .proxy(viewModel.proxy)
                    .onTicksUpdated { ticks, info in
                        let seconds = ticks / 1000
                        viewModel.updatePlaybackPosition(seconds)
                        viewModel.duration = info.length / 1000
                        playbackInfo = info
                        if !isSeeking {
                            seekValue = Double(seconds)
                        }
                        viewModel.setSubtitleTracks(info.subtitleTracks)
                    }
                    .onStateUpdated { state, _ in
                        viewModel.isPlaying = (state == .playing)
                    }
                } else {
                    Text("Unable to play this item.")
                        .padding()
                }

                // Center controls
                if playbackInfo != nil {
                    HStack(spacing: 40) {
                        Button {
                            viewModel.proxy.jumpBackward(5)
                        } label: {
                            Image(systemName: "gobackward.5")
                                .font(.system(size: 32))
                        }
                        .buttonStyle(.glass)
                        
                        Button {
                            if viewModel.isPlaying {
                                viewModel.proxy.pause()
                            } else {
                                viewModel.proxy.play()
                            }
                        } label: {
                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 40))
                        }
                        .buttonStyle(.glass)
                        
                        Button {
                            viewModel.proxy.jumpForward(5)
                        } label: {
                            Image(systemName: "goforward.5")
                                .font(.system(size: 32))
                        }
                        .buttonStyle(.glass)
                    }
                }
            }

            // Playback slider and subtitle picker
            if let info = playbackInfo {
                HStack {
                    Slider(value: Binding(
                        get: { isSeeking ? seekValue : Double(viewModel.playbackPosition) },
                        set: { newValue in
                            seekValue = newValue
                        }
                    ), in: 0...Double(viewModel.duration), onEditingChanged: { editing in
                        isSeeking = editing
                        if !editing {
                            viewModel.proxy.setSeconds(.seconds(Int(seekValue)))
                        }
                    })
                    .padding(.horizontal)

                    // Subtitle picker
                    if !viewModel.subtitleTracks.isEmpty {
                        Picker("Subtitles", selection: Binding(
                            get: { viewModel.selectedSubtitleIndex ?? -1 },
                            set: { idx in
                                if idx >= 0 { viewModel.selectSubtitle(index: idx) }
                            }
                        )) {
                            Text("Subtitles Off").tag(-1)
                            ForEach(viewModel.subtitleTracks, id: \ .index) { track in
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
        }
        .background(Color.black)
    }

    private var playbackURL: URL? {
        guard let id = item.id else { return nil }
        var components = URLComponents(url: server.url, resolvingAgainstBaseURL: false)
        components?.path = "/Videos/\(id)/stream"
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "Static", value: "true"),
            URLQueryItem(name: "mediaSourceId", value: id),
            URLQueryItem(name: "api_key", value: user.accessToken)
        ]
        queryItems.append(URLQueryItem(name: "deviceId", value: "deviceId"))
        components?.queryItems = queryItems
        return components?.url
    }

    private var startTimeSeconds: Int {
        guard let ticks = item.userData?.playbackPositionTicks else { return 0 }
        return Int(ticks / 10_000_000)
    }
}
