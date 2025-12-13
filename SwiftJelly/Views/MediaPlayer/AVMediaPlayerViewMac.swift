import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerViewMac: View {
    @State private var nowPlaying: BaseItemDto
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var showInfoSheet = false
    @State private var playbackToken = UUID()
    @State private var playbackEndObserver: NSObjectProtocol?
    @State private var isAutoLoadingNext = false
    @State private var didConfigureWindow = false
    @State private var playbackInfo: PlaybackInfoResponse?
    @State private var audioTracks: [PlaybackAudioTrack] = []
    @State private var selectedAudioTrack: PlaybackAudioTrack?
    @State private var preferredAudioLanguage: String?
    @State private var isSwitchingAudio = false

    init(item: BaseItemDto) {
        _nowPlaying = State(initialValue: item)
    }

    var body: some View {
        Group {
            if let player = player {
                AVPlayerMac(player: player)
                    .task(id: player.timeControlStatus) {
                        await PlaybackUtilities.reportPlaybackProgress(player: player, item: nowPlaying)
                    }
            } else if isLoading {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black, ignoresSafeAreaEdges: .all)
                    .task(id: playbackToken) {
                        await loadPlayer(audioIndex: selectedAudioTrack?.index)
                    }
            }
        }
        .ignoresSafeArea()
        .navigationTitle(nowPlaying.seriesName ?? nowPlaying.name ?? "Media Player")
        .navigationSubtitle(nowPlaying.seasonEpisodeString ?? "")
        .windowFullScreenBehavior(.disabled)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .gesture(WindowDragGesture())
        .inspector(isPresented: $showInfoSheet) {
            Form {
                Section {
                    Text(nowPlaying.name ?? "Unknown")
                }

                if let overview = nowPlaying.overview, !overview.isEmpty {
                    Section("Overview") { Text(overview) }
                }

                if let year = nowPlaying.productionYear {
                    Section("Year") { Text(String(year)) }
                }
            }
            .formStyle(.grouped)
        }
        .toolbar {
            Button {
                showInfoSheet.toggle()
            } label: {
                Image(systemName: "info")
            }

            if audioTracks.count > 1 {
                Menu {
                    ForEach(audioTracks) { track in
                        Button(track.displayName) {
                            Task { await switchAudioTrack(to: track) }
                        }
                        .disabled(isSwitchingAudio || track == selectedAudioTrack)
                    }
                } label: {
                    Label("Audio", systemImage: "speaker.wave.2.fill")
                }
                .menuIndicator(.hidden)
            }
        }
        .overlay {
            if isAutoLoadingNext {
                ProgressView()
                    .controlSize(.extraLarge)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if !didConfigureWindow {
                configureWindow()
                didConfigureWindow = true
            }
        }
        .onDisappear {
            Task { await cleanup() }
        }
    }

    private func configureWindow() {
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "media-player-AppWindow-1" }) {
            let (videoWidth, videoHeight) = PlaybackUtilities.getVideoDimensions(from: nowPlaying)
            
            window.aspectRatio = NSSize(width: videoWidth, height: videoHeight)
            
            let maxWidth: CGFloat = 1024
            let maxHeight: CGFloat = 576
            
            let widthRatio = maxWidth / CGFloat(videoWidth)
            let heightRatio = maxHeight / CGFloat(videoHeight)
            let scale = min(widthRatio, heightRatio, 1.0)
            
            let scaledWidth = CGFloat(videoWidth) * scale
            let scaledHeight = CGFloat(videoHeight) * scale
            
            window.setContentSize(NSSize(width: scaledWidth, height: scaledHeight))
        }
    }

    private func loadPlayer(audioIndex: Int? = nil, resumeSeconds: Double? = nil) async {
        do {
            let session = try await PlaybackUtilities.loadPlaybackInfo(
                for: nowPlaying,
                audioStreamIndex: audioIndex,
                resumeSeconds: resumeSeconds
            )
            await MainActor.run {
                removePlaybackEndObserver()
                player = session.player
                playbackInfo = session.info
                isLoading = false
                audioTracks = PlaybackAudioTrack.tracks(from: session.info)
                selectedAudioTrack = resolveSelectedTrack(preferredIndex: audioIndex)
                registerEndObserver(for: session.player)
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func cleanup() async {
        removePlaybackEndObserver()
        guard let player = player else { return }
        await PlaybackUtilities.reportPlaybackAndCleanup(player: player, item: nowPlaying)
        await MainActor.run {
            self.player = nil
        }
    }
    
    private func registerEndObserver(for player: AVPlayer) {
        playbackEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            handlePlaybackCompletion()
        }
    }
    
    private func removePlaybackEndObserver() {
        if let observer = playbackEndObserver {
            NotificationCenter.default.removeObserver(observer)
            playbackEndObserver = nil
        }
    }
    
    private func handlePlaybackCompletion() {
        guard nowPlaying.type == .episode,
              !isAutoLoadingNext,
              let currentPlayer = player else {
            return
        }
        
        isAutoLoadingNext = true
        removePlaybackEndObserver()
        let finishedItem = nowPlaying
        
        Task {
            await PlaybackUtilities.reportPlaybackStop(player: currentPlayer, item: finishedItem)
            await MainActor.run {
                currentPlayer.replaceCurrentItem(with: nil)
            }
            
            let nextEpisode = try? await JFAPI.loadNextEpisode(after: finishedItem)
            
            await MainActor.run {
                defer { isAutoLoadingNext = false }
                guard let nextEpisode,
                      nextEpisode.id != finishedItem.id else {
                    return
                }
                
                nowPlaying = nextEpisode
                player = nil
                isLoading = true
                playbackToken = UUID()
            }
        }
    }

    private func resolveSelectedTrack(preferredIndex: Int?) -> PlaybackAudioTrack? {
        if let preferredIndex,
           let match = audioTracks.first(where: { $0.index == preferredIndex }) {
            preferredAudioLanguage = match.languageCode ?? preferredAudioLanguage
            return match
        }

        if let preferredAudioLanguage,
           let languageMatch = audioTracks.first(where: { $0.languageCode?.lowercased() == preferredAudioLanguage.lowercased() }) {
            return languageMatch
        }

        if let defaultIndex = playbackInfo?.mediaSource.defaultAudioStreamIndex,
           let defaultMatch = audioTracks.first(where: { $0.index == defaultIndex }) {
            preferredAudioLanguage = defaultMatch.languageCode ?? preferredAudioLanguage
            return defaultMatch
        }

        preferredAudioLanguage = audioTracks.first?.languageCode ?? preferredAudioLanguage
        return audioTracks.first
    }

    private func switchAudioTrack(to track: PlaybackAudioTrack) async {
        guard track != selectedAudioTrack else { return }
        preferredAudioLanguage = track.languageCode ?? preferredAudioLanguage
        isSwitchingAudio = true
        let resumeSeconds = player?.currentTime().seconds ?? 0
        player = nil
        isLoading = true

        await loadPlayer(audioIndex: track.index, resumeSeconds: resumeSeconds)

        await MainActor.run {
            isSwitchingAudio = false
        }
    }
}
