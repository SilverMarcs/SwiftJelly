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
        VStack {
            if isLoading {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black, ignoresSafeAreaEdges: .all)
                    .task { await loadPlaybackInfo() }
            } else if let player {
                Group {
                    #if os(macOS)
                    AVPlayerMac(player: player)
                    #else
                    AVPlayerIos(player: player)
                    #endif
                }
                .ignoresSafeArea()
            }
        }
        .navigationTitle(item.name ?? "Media Player")
        .toolbar {
            Button {
                showInfoSheet = true
            } label: {
                Image(systemName: "info")
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
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)
        }
        #endif
    }

    private func loadPlaybackInfo() async {
        do {
            let item = self.item
            let subtitleStreamIndex = item.mediaSources?
                .first?
                .mediaStreams?
                .first(where: { $0.type == .subtitle })?
                .index

            let info = try await JFAPI.getPlaybackInfo(
                for: item,
                subtitleStreamIndex: subtitleStreamIndex
            )

            let player = AVPlayer(url: info.playbackURL)
            self.player = player
            self.isLoading = false

            let time = CMTime(seconds: Double(item.startTimeSeconds), preferredTimescale: 1)
            await player.seek(to: time)
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
        #if !os(macOS)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
        
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
