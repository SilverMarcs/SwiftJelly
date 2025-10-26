import SwiftUI
import AVKit
import JellyfinAPI

struct AVMediaPlayerView: View {
    @Environment(\.scenePhase) var scenePhase
    
    let item: BaseItemDto
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var showInfoSheet = false
    @State private var timeObserver: Any?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black, ignoresSafeAreaEdges: .all)
                    .task { await loadPlaybackInfo() }
            } else if let player {
                #if os(macOS)
                AVPlayerMac(player: player)
                #else
                AVPlayerIos(player: player)
                #endif
            }
        }
        .ignoresSafeArea()
        .toolbar {
            Button {
                showInfoSheet = true
            } label: {
                Image(systemName: "info")
            }
        }
        .onDisappear {
            #if !os(macOS)
            OrientationManager.shared.lockOrientation(.all)
            #endif
            Task {
                await cleanup()
            }
        }
        #if !os(macOS)
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                // resume timer tracking
                if let player = player {
                    setupPeriodicTimeObserver(for: player)
                }
            } else if scenePhase == .background {
                // pause timer tracking
                if let observer = timeObserver {
                    player?.removeTimeObserver(observer)
                    timeObserver = nil
                }
            }
        }
        .onAppear {
            OrientationManager.shared.lockOrientation(.landscape, andRotateTo: .landscapeRight)
        }
        #else
        .navigationTitle(item.seriesName ?? item.name ?? "Media Player")
        .navigationSubtitle(item.seasonEpisodeString ?? "Movie")
        .onAppear {
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "media-player-AppWindow-1" }) {
                let videoWidth = item.mediaSources?.first?.mediaStreams?.first?.width ?? 1024
                let videoHeight = item.mediaSources?.first?.mediaStreams?.first?.height ?? 576
                
                // Set aspect ratio based on actual video dimensions
                window.aspectRatio = NSSize(width: videoWidth, height: videoHeight)
                
                // Calculate scaled size to fit within 1024x576
                let maxWidth: CGFloat = 1024
                let maxHeight: CGFloat = 576
                
                let widthRatio = maxWidth / CGFloat(videoWidth)
                let heightRatio = maxHeight / CGFloat(videoHeight)
                let scale = min(widthRatio, heightRatio, 1.0) // Don't scale up, only down
                
                let scaledWidth = CGFloat(videoWidth) * scale
                let scaledHeight = CGFloat(videoHeight) * scale
                
                window.setContentSize(NSSize(width: scaledWidth, height: scaledHeight))
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            Form {
                Section {
                    Text(item.name ?? "Unknown")
                }

                if let overview = item.overview, !overview.isEmpty {
                    Section("Overview") { Text(overview) }
                }

                if let year = item.productionYear {
                    Section("Year") { Text(String(year)) }
                }
            }
            .formStyle(.grouped)
            .frame(maxWidth: 400)
        }
        
        #endif
    }

    private func loadPlaybackInfo() async {
        do {
            let item = self.item
            
            // Load metadata FIRST (before creating player)
            #if !os(macOS)
            let metadata = await item.createMetadataItems()
            #endif
            
            let subtitleStreamIndex = item.mediaSources?
                .first?
                .mediaStreams?
                .first(where: { $0.type == .subtitle })?
                .index

            let info = try await JFAPI.getPlaybackInfo(
                for: item,
                subtitleStreamIndex: subtitleStreamIndex
            )

            let playerItem = AVPlayerItem(url: info.playbackURL)
            
            #if !os(macOS)
            // Apply pre-loaded metadata
            playerItem.externalMetadata = metadata
            #endif

            let player = AVPlayer(playerItem: playerItem)
            self.player = player
            self.isLoading = false

            let time = CMTime(seconds: Double(item.startTimeSeconds), preferredTimescale: 1)
            await player.seek(to: time)
            
            #if !os(macOS)
            try? AVAudioSession.sharedInstance().setActive(true)
            #endif
            
            player.play()
            
            setupPeriodicTimeObserver(for: player)
        } catch {
            self.isLoading = false
        }
    }
    
    private func setupPeriodicTimeObserver(for player: AVPlayer) {
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 10, preferredTimescale: 1), queue: .main) { time in
            Task {
                try? await JFAPI.reportPlaybackProgress(for: self.item, positionTicks: time.seconds.toPositionTicks)
            }
        }
    }

    private func cleanup() async {
        guard let player = player else { return }
        player.pause()

        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
        
        let currentTime = player.currentTime()
        let seconds = Int(currentTime.seconds)
        
        try? await JFAPI.reportPlaybackProgress(
            for: item,
            positionTicks: seconds.toPositionTicks
        )
        
        player.replaceCurrentItem(with: nil)
        self.player = nil

        try? await Task.sleep(nanoseconds: 100_000_000)
        if let handler = RefreshHandlerContainer.shared.refresh {
            await handler()
        }
    }
}

// https://developer.apple.com/documentation/avkit/customizing-the-tvos-playback-experience

// Creating a skip button for a preroll ad

//let eventController = AVPlayerInterstitialEventController(primaryPlayer: mediaPlayer)
//
//let event = AVPlayerInterstitialEvent(primaryItem: interstitialItem, time: .zero)
//event.restrictions = [
//    .requiresPlaybackAtPreferredRateForAdvancement,
//    .constrainsSeekingForwardInPrimaryContent
//]
//
//eventController.events.append(event)
//
//
//func playerViewController(playerViewController: AVPlayerViewController, willPresent interstitial: AVInterstitialTimeRange) {
//    showSkipButton(afterTime: 5.0, onPress: {
//        eventController.cancelCurrentEvent(withResumptionOffset: CMTime.zero)
//    })
//}

