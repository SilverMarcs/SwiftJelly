import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerView: View {
    let mediaItem: MediaItem
    @State private var player: AVPlayer?
    @State private var playbackInfo: PlaybackInfoResponse?
    @State private var isLoading = true
    @State private var error: Error?
    let startTimeSeconds: Int
    let reporter: PlaybackReporterProtocol
    
    init(mediaItem: MediaItem) {
        self.mediaItem = mediaItem
        self.startTimeSeconds = mediaItem.startTimeSeconds
        
        switch mediaItem {
        case .jellyfin(let item):
            self.reporter = JellyfinPlaybackReporter(item: item)
        case .local(let file):
            self.reporter = LocalPlaybackReporter(file: file)
        }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
            } else if let error = error {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                    Text("Playback Error")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else if let player = player, let playbackInfo = playbackInfo {
                playerView(player: player, playbackInfo: playbackInfo)
            }
        }
        .task {
            await loadPlaybackInfo()
        }
    }
    
    @ViewBuilder
    private func playerView(player: AVPlayer, playbackInfo: PlaybackInfoResponse) -> some View {
        #if os(macOS)
        AVPlayerMac(startTimeSeconds: startTimeSeconds, player: player)
            .ignoresSafeArea()
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
            .aspectRatio(16/9, contentMode: .fit)
            .gesture(WindowDragGesture())
            .navigationTitle(mediaItem.name ?? "Media Player")
            .onDisappear {
                cleanup(playbackInfo: playbackInfo)
            }
        #else
        AVPlayerIos(startTimeSeconds: startTimeSeconds, player: player)
            .ignoresSafeArea()
            .onDisappear {
                cleanup(playbackInfo: playbackInfo)
                OrientationManager.shared.lockOrientation(.all)
            }
            .onAppear {
                OrientationManager.shared.lockOrientation(.landscape, andRotateTo: .landscapeRight)
            }
        #endif
    }
    
    private func loadPlaybackInfo() async {
        do {
            switch mediaItem {
            case .jellyfin(let item):
                // Find a subtitle track to enable (prefer English)
                let subtitleStreamIndex = findPreferredSubtitleStream(item: item)
                
                // Request playback info with device profile for AVPlayer compatibility
                let info = try await JFAPI.getPlaybackInfo(
                    for: item,
                    subtitleStreamIndex: subtitleStreamIndex
                )
                
                // Debug logging
                print("🎬 Playback Info:")
                print("   URL: \(info.playbackURL)")
                print("   Method: \(info.playMethod)")
                print("   Selected subtitle index: \(subtitleStreamIndex?.description ?? "none")")
                print("   Has subtitles: \(info.mediaSource.mediaStreams?.contains(where: { $0.type == .subtitle }) ?? false)")
                if let subtitleStreams = info.mediaSource.mediaStreams?.filter({ $0.type == .subtitle }) {
                    print("   Subtitle tracks: \(subtitleStreams.count)")
                    for (index, stream) in subtitleStreams.enumerated() {
                        let selected = stream.index == subtitleStreamIndex ? "✓" : " "
                        print("     [\(selected)] \(stream.displayTitle ?? stream.language ?? "Unknown") - \(stream.codec ?? "?")")
                    }
                }
                
                await MainActor.run {
                    self.playbackInfo = info
                    let player = AVPlayer(url: info.playbackURL)
                    self.player = player
                    self.isLoading = false
                }
                
                // Wait for player to load, then check for subtitle tracks
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                if let player = await self.player {
                    await inspectPlayerSubtitles(player: player)
                }
                
                // Update reporter with server's playSessionID
                if let jellyfinReporter = reporter as? JellyfinPlaybackReporter {
                    jellyfinReporter.updatePlaySessionID(info.playSessionID)
                }
                
                // Report playback start
                reporter.reportStart(positionSeconds: startTimeSeconds)
                
            case .local(let file):
                // Local files use direct URL
                await MainActor.run {
                    self.player = AVPlayer(url: file.url)
                    self.isLoading = false
                }
                
                reporter.reportStart(positionSeconds: startTimeSeconds)
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    @MainActor
    private func inspectPlayerSubtitles(player: AVPlayer) {
        guard let currentItem = player.currentItem else {
            print("⚠️ No current item in player")
            return
        }
        
        guard let asset = currentItem.asset as? AVURLAsset else {
            print("⚠️ Asset is not AVURLAsset")
            return
        }
        
        print("\n📺 AVPlayer Asset Info:")
        print("   URL: \(asset.url)")
        
        // Check for subtitle/legible media selection group
        let mediaCharacteristics: [AVMediaCharacteristic] = [
            .legible,
            .audible,
            .visual
        ]
        
        for characteristic in mediaCharacteristics {
            if let group = asset.mediaSelectionGroup(forMediaCharacteristic: characteristic) {
                print("   \(characteristic.rawValue) group found:")
                print("     Options: \(group.options.count)")
                print("     Allows empty selection: \(group.allowsEmptySelection)")
                
                for (index, option) in group.options.enumerated() {
                    let displayName = option.displayName
                    let locale = option.locale?.identifier ?? "nil"
                    let mediaType = option.mediaType.rawValue ?? "nil"
                    print("       [\(index)] \(displayName) - locale: \(locale), type: \(mediaType)")
                }
            } else {
                print("   No \(characteristic.rawValue) group found")
            }
        }
        
        // Check current selection
        if let legibleGroup = asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
            let currentSelection = currentItem.currentMediaSelection.selectedMediaOption(in: legibleGroup)
            print("   Current subtitle selection: \(currentSelection?.displayName ?? "None")")
        }
        
        print("")
    }
    
    private func findPreferredSubtitleStream(item: BaseItemDto) -> Int? {
        guard let mediaSource = item.mediaSources?.first,
              let subtitleStreams = mediaSource.mediaStreams?.filter({ $0.type == .subtitle }),
              !subtitleStreams.isEmpty else {
            return nil
        }
        
        // Priority order:
        // 1. English (non-SDH/non-forced)
        // 2. First English subtitle
        // 3. First subtitle track
        
        // Try to find English non-SDH
        if let englishStream = subtitleStreams.first(where: { stream in
            let language = stream.language?.lowercased() ?? ""
            let title = stream.displayTitle?.lowercased() ?? ""
            return (language.contains("eng") || language.contains("en")) &&
                   !title.contains("sdh") &&
                   !title.contains("hearing") &&
                   !(stream.isForced ?? false)
        }) {
            return englishStream.index
        }
        
        // Try any English
        if let englishStream = subtitleStreams.first(where: { stream in
            let language = stream.language?.lowercased() ?? ""
            return language.contains("eng") || language.contains("en")
        }) {
            return englishStream.index
        }
        
        // Return first subtitle
        return subtitleStreams.first?.index
    }
    
    private func cleanup(playbackInfo: PlaybackInfoResponse? = nil) {
        guard let player = player else { return }
        guard let time = player.currentItem?.currentTime() else { return }

        let seconds = Int(time.seconds)
        
        reporter.reportPause(positionSeconds: seconds)
        reporter.reportProgress(positionSeconds: seconds, isPaused: true)
        reporter.reportStop(positionSeconds: seconds)
        player.pause()
        
        // Stop accessing security-scoped resource for local files
        #if os(macOS)
        if case .local(let file) = mediaItem {
            file.stopAccessingSecurityScopedResource()
        }
        #endif
        
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            if let handler = RefreshHandlerContainer.shared.refresh {
                await handler()
            }
        }
    }
}
