import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerView: View {
    let mediaItem: MediaItem
    @State private var player: AVPlayer?
    @State private var isLoading = true
    
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
        
        reporter.reportStart(positionSeconds: startTimeSeconds)
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
            } else if let player = player {
                playerView(player: player)
            }
        }
        .task {
            await loadPlaybackInfo()
        }
    }
    
    @ViewBuilder
    private func playerView(player: AVPlayer) -> some View {
        #if os(macOS)
        AVPlayerMac(startTimeSeconds: startTimeSeconds, player: player)
            .ignoresSafeArea()
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
            .aspectRatio(16/9, contentMode: .fit)
            .gesture(WindowDragGesture())
            .navigationTitle(mediaItem.name ?? "Media Player")
            .onDisappear {
                cleanup()
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
                // Get first available subtitle stream index to make subtitles available in player
                let subtitleStreamIndex = item.mediaSources?.first?.mediaStreams?.first(where: { $0.type == .subtitle })?.index
                
                // Request playback info with device profile for AVPlayer compatibility
                let info = try await JFAPI.getPlaybackInfo(
                    for: item,
                    subtitleStreamIndex: subtitleStreamIndex
                )
            
                let player = AVPlayer(url: info.playbackURL)
                self.player = player
                self.isLoading = false

                
            case .local(let file):
                // Local files use direct URL
                self.player = AVPlayer(url: file.url)
                self.isLoading = false
                
                reporter.reportStart(positionSeconds: startTimeSeconds)
            }
        } catch {
            self.isLoading = false
        }
    }
    
    private func cleanup() {
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
